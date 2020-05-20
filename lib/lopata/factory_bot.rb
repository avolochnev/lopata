require_relative 'active_record'

module Lopata
  module FactoryBot
    # To be included in Lopata::Scenario
    module Methods
      def create(*params)
        cleanup_later ::FactoryBot.create(*params)
      end

      def find_created(cls, params)
        cleanup_later cls.where(params).take
      end

      def cleanup_later(object)
        return nil unless object
        @created_objects ||= []
        @created_objects << object
        object
      end
    end

    # To be included in Lopata::ScenarioBuilder
    module DSL
    end
  end
end

Lopata::Scenario.include Lopata::FactoryBot::Methods
Lopata::ScenarioBuilder.include Lopata::FactoryBot::DSL

Lopata.configure do |c|
  c.after_scenario { cleanup @created_objects }
end

::FactoryBot.find_definitions unless Lopata::Config.readonly
