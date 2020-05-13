class Lopata::World
  attr_reader :scenarios

  def initialize
    @scenarios = []
  end

  def start
    notify_observers(:started, self)
  end

  # Called at the end of test running.
  #
  # Notifies observers about testing finish
  def finish
    notify_observers(:finished, self)
  end

  def notify_observers(event, context)
    observers.each do |observer|
      observer.send event, context
    end
  end

  # Define observers based on configuration
  def observers
    @observers ||= [Lopata::Observers::ConsoleOutputObserver.new]
  end
end