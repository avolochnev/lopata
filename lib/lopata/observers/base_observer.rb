module Lopata
  module Observers
    class BaseObserver
      def started(world)
      end

      def finished(world)
      end

      def scenario_started(scenario)
      end

      def scenario_finished(scenario)
      end

      def step_started(step)
      end

      def step_finished(step)
      end
    end
  end
end