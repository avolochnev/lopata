module Lopata
  module Role
    # To be included in Lopata::Scenario
    module Methods
      def current_role
        metadata[:as]
      end
    end

    # To be included in Lopata::ScenarioBuilder
    module DSL
      def as(*args, &block)
        @roles = args.flatten
        @roles << Lopata::ScenarioBuilder::CalculatedValue.new(&block) if block_given?
        @role_options = nil
      end

      def role_options
        @role_options ||= build_role_options
      end

      def without_user
        @without_user = true
      end

      def build_role_options
        return [] unless roles
        [Lopata::ScenarioBuilder::Diagonal.new(:as, roles.map { |r| [Lopata::Config.role_descriptions[r], r] })]
      end

      def roles
        return false if @without_user
        @roles ||= [Lopata::Config.default_role].compact
      end

      def diagonals
        super + role_options
      end
    end
  end
end

Lopata::Scenario.include Lopata::Role::Methods
Lopata::ScenarioBuilder.prepend Lopata::Role::DSL