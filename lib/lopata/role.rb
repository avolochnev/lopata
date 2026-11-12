module Lopata
  # Adds ability to run scenarios by given user roles
  #
  # @example Usage
  #     require 'lopata/role'
  #     Lopata.configure do |c|
  #       c.role_descriptions = {
  #         user: 'User',
  #         admin: 'Admin'
  #       }
  #       c.default_role = :user
  #       c.before_scenaro 'setup user'
  #     end
  #     Lopata.shared_step 'setup user' do
  #       setup { @user = User.create(role: current_role) if current_role }
  #       cleanup :user
  #     end
  #     Lopata.define 'login' do
  #       # will generate 2 scenarios, one for :user and one for :admin
  #       as :user, :admin
  #       action 'login'
  #       # verify the user is logged in
  #     end
  #
  # @see Lopata::Configuration#role_descriptions
  # @see Lopata::Configuration#default_role
  module Role
    # To be included in Lopata::Scenario
    module Methods
      # @return [Symbol, nil] user role for current scenario or nil, if scenario is running without user.
      def current_role
        metadata[:as]
      end
    end

    # To be included in Lopata::ScenarioBuilder
    module DSL
      # Enumerate the roles the scenario to be runned under.
      # If not invoked the default role only will be used.
      #
      # The scenario should be set to use the role via before_scenario step using #current_role param.
      #
      # When block without arguments is given, it defines a role group: the variants (diagonals and options)
      # declared inside the block are applied to the given roles only. Several role groups may be declared,
      # the scenarios are generated for each group separately.
      #
      # @example Role groups
      #     Lopata.define 'scenario' do
      #       as :user, :admin do
      #         diagonal :pc, 'one' => 1, 'two' => 2
      #       end
      #       as_first :guest do
      #         diagonal :pc, 'three' => 3
      #       end
      #     end
      #
      # @param args [Array<Symbol>] list of roles the scenario to be runned with.
      # @param block [Block] the block to calculate role from scenario metadata (block with one argument),
      #   or the role group definition (block without arguments).
      def as(*args, &block)
        return add_role_group(args, true, &block) if block && block.arity == 0
        raise_if_role_groups_defined
        @roles = args.flatten
        @roles << Lopata::ScenarioBuilder::CalculatedValue.new(&block) if block_given?
        @use_all_roles = true
        @role_options = nil
      end

      # Enumerate the roles the scenario can be run.
      #
      # The scenario should be set to use the role via before_scenario step using #current_role param.
      #
      # Only first role will be used if scenario has no options or diagonales. Some first roles will be used if
      # options or diagonales are declared, in order of appearence.
      #
      # Use this to describe possible roles, but not needed to run scenario with all of them in order to save time
      # of running.
      #
      # When block is given, it defines a role group. See #as for details.
      #
      # @param args [Array<Symbol>] list of roles the scenario to be runned with.
      def as_first(*args, &block)
        return add_role_group(args, false, &block) if block
        raise_if_role_groups_defined
        @roles = args.flatten
        @use_all_roles = false
        @role_options = nil
      end

      # @private
      def role_options
        @role_options ||= build_role_options
      end

      # Marks scenario to be runned without user.
      #
      # @example
      #     Lopata.define 'scenario withou user' do
      #       without_user
      #       it 'does not define the user' do
      #         expect(current_role).to be_nil
      #       end
      #     end
      def without_user
        @without_user = true
      end

      # @private
      def build_role_options
        return [] unless roles
        role_variants = roles.map { |r| [Lopata.configuration.role_descriptions[r], r] }
        [Lopata::ScenarioBuilder::Diagonal.new(:as, role_variants, @use_all_roles)]
      end

      # @private
      def roles
        return false if @without_user
        @roles ||= [Lopata.configuration.default_role].compact
      end

      # @private
      def diagonals
        return super + role_options unless @current_role_group
        super + @current_role_group.diagonals + @current_role_group.role_options
      end

      # @private
      def options
        return super unless @current_role_group
        super + @current_role_group.options
      end

      # @private
      def option_combinations
        return super() unless @role_groups
        @role_groups.flat_map do |group|
          begin
            @current_role_group = group
            (options + diagonals).each(&:reset)
            super()
          ensure
            @current_role_group = nil
          end
        end
      end

      private

        def add_role_group(roles, use_all_roles, &block)
          if @roles || @without_user
            raise ArgumentError, 'Role groups (as/as_first with block) can not be combined with plain role declaration'
          end
          group = RoleGroup.new(roles.flatten, use_all_roles)
          group.instance_exec(&block)
          (@role_groups ||= []) << group
        end

        def raise_if_role_groups_defined
          return unless @role_groups
          raise ArgumentError, 'Plain role declaration can not be combined with role groups (as/as_first with block)'
        end
    end

    # Set of roles with own variants. Variants defined in the group are applied to the group roles only.
    #
    # @see DSL#as
    class RoleGroup
      # @private
      attr_reader :roles, :options, :diagonals

      # @private
      def initialize(roles, use_all_roles)
        @roles, @use_all_roles = roles, use_all_roles
        @options, @diagonals = [], []
      end

      # Define option for the role group.
      # @see Lopata::ScenarioBuilder#option
      def option(metadata_key, variants)
        @options << Lopata::ScenarioBuilder::Option.new(metadata_key, variants)
      end

      # Define diagonal for the role group.
      # @see Lopata::ScenarioBuilder#diagonal
      def diagonal(metadata_key, variants)
        @diagonals << Lopata::ScenarioBuilder::Diagonal.new(metadata_key, variants)
      end

      # @private
      def role_options
        @role_options ||= begin
          role_variants = roles.map { |r| [Lopata.configuration.role_descriptions[r], r] }
          [Lopata::ScenarioBuilder::Diagonal.new(:as, role_variants, @use_all_roles)]
        end
      end
    end
  end
end

Lopata::Scenario.include Lopata::Role::Methods
# Prepend the module to overload #diagonals method
Lopata::ScenarioBuilder.prepend Lopata::Role::DSL