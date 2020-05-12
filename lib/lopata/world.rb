class Lopata::World
  attr_reader :scenarios, :observers

  def initialize
    @scenarios = []
    @observers = []
  end

  # Loads scenarios for running in current session
  #
  # @param args [Array<String>] files to be load.
  #   All files from default location to be loaded if empty.
  def load_scenarios(*args)
    if args.empty?
      load_all_scenarios
    else
      args.each do |file|
        load File.expand_path(file)
      end
    end
  end

  # Loads all scenarios from predefined paths
  def load_all_scenarios
    Dir["scenarios/**/*.rb"].each { |f| load File.expand_path(f) }
  end

  def load_shared_steps
    Dir["shared_steps/**/*rb"].each { |f| load File.expand_path(f) }
  end

  # Called at the end of test running.
  #
  # Notifies observers about testing finish
  def finish
    notify_observers(:finished, self)
  end

  def notify_observers(event, context)
    @observers.each do |observer|
      observer.send event, context
    end
  end

  # Define observers based on configuration
  def setup_observers
    @observers = [Lopata::Observers::ConsoleOutputObserver.new]
  end
end