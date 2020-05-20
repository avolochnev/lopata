require 'rspec/expectations'

class Lopata::Scenario
  include RSpec::Matchers

  attr_reader :title, :metadata

  def initialize(title, options_title, metadata = {})
    @title = [title, options_title].compact.reject(&:empty?).join(' ')
    @metadata = metadata
  end

  def execution
    @execution ||= Execution.new(self)
  end

  private

  def method_missing(method, *args, &block)
    if metadata.keys.include?(method)
      metadata[method]
    else
      super
    end
  end

  def respond_to_missing?(method, *)
    metadata.keys.include?(method) or super
  end

  class Execution
    extend Forwardable
    attr_reader :scenario, :status, :steps
    def_delegators :scenario, :title

    def initialize(scenario)
      @scenario = scenario
      @status = :not_runned
      @steps = []
    end

    def run
      @status = :running
      world.notify_observers(:scenario_started, self)
      steps_in_running_order.each(&method(:run_step))
      @status = steps.all?(&:passed?) ? :passed : :failed
      world.notify_observers(:scenario_finished, self)
    end

    def run_step(step)
      return if step.skipped?
      step.run(scenario)
      skip_rest if step.failed? && step.skip_rest_on_failure?
    end

    def world
      @world ||= Lopata::Config.world
    end

    def failed?
      status == :failed
    end

    def steps_in_running_order
      steps.reject(&:teardown_group?) + steps.select(&:teardown_group?)
    end

    def skip_rest
      steps.select { |s| s.status == :not_runned && !s.teardown? }.each(&:skip!)
    end
  end
end
