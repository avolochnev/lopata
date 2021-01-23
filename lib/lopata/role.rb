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
      # @param args [Array<Symbol>] list of roles the scenario to be runned with.
      # @param block [Block] the block to calculate role from scenario metadata.
      def as(*args, &block)
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
      # @param args [Array<Symbol>] list of roles the scenario to be runned with.
      def as_first(*args, &block)
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
        super + role_options
      end
    end
  end
end

Lopata::Scenario.include Lopata::Role::Methods
# Prepend the module to overload #diagonals method
Lopata::ScenarioBuilder.prepend Lopata::Role::DSL