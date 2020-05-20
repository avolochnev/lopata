module Lopata
  module ActiveRecord
    # To be included in Lopata::Scenario
    module Methods
      def cleanup(*objects)
        return if Lopata::Config.ops[:keep]
        objects.flatten.compact.each do |o|
          begin
            o.reload.destroy!
          rescue ::ActiveRecord::RecordNotFound
            # Already destroyed
          end
        end
      end

      def reload(*objects)
        objects.flatten.each(&:reload)
      end
    end

    # To be included in Lopata::ScenarioBuilder
    module DSL
      def cleanup(*vars, &block)
        unless vars.empty?
          teardown do
            cleanup vars.map { |v| instance_variable_get "@#{v}" }
          end
        end
        teardown &block if block_given?
      end
    end
  end
end

Lopata::Scenario.include Lopata::ActiveRecord::Methods
Lopata::ScenarioBuilder.include Lopata::ActiveRecord::DSL