module Lopata
  module Observers
    # Lopata allows observe scenarios execution.
    # All the observers are subclasses of Lopata::Observers::BaseObserver.
    #
    # @see Lopata::Observers::ConsoleOutputObserver for implementation example
    class BaseObserver
      # Called before scenarios execution.
      # All the scenarios are prepared at the moment, so it may be used to get number of scenarios
      # via world.scenarios.count
      #
      # @param world [Lopata::World]
      def started(world)
      end

      # Called after all scenarios execution.
      # All the scenarios are finished at the moment, so it may be used for output statistics.
      #
      # @param world [Lopata::World]
      def finished(world)
      end

      # Called before single scenario execution.
      # @param scenario [Lopata::Scenario::Execution]
      def scenario_started(scenario)
      end

      # Called after single scenario execution.
      # @param scenario [Lopata::Scenario::Execution]
      def scenario_finished(scenario)
      end
    end
  end
end