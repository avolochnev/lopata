# Container for gobal non-configuration data
class Lopata::World
  # Scenarios are selected for current run
  # @return [Array<Lopata::Scenario::Execution>]
  attr_reader :scenarios

  # @private
  def initialize
    @scenarios = []
  end

  # @private
  def notify_observers(event, context)
    observers.each do |observer|
      observer.send event, context
    end
  end

  private

  # Define observers based on configuration
  def observers
    Lopata.configuration.observers
  end
end