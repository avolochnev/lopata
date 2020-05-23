require 'rspec/expectations'

class Lopata::Scenario
  include RSpec::Matchers

  attr_reader :execution

  def initialize(execution)
    @execution = execution
  end

  # Marks current step as pending
  def pending(message = nil)
    execution.current_step.pending!(message)
  end

  def metadata
    execution.metadata
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
    attr_reader :scenario, :status, :steps, :title, :current_step

    def initialize(title, options_title, metadata = {})
      @title = [title, options_title].compact.reject(&:empty?).join(' ')
      @metadata = metadata
      @status = :not_runned
      @steps = []
      @scenario = Lopata::Scenario.new(self)
    end

    def run
      @status = :running
      world.notify_observers(:scenario_started, self)
      steps_in_running_order.each(&method(:run_step))
      @status = steps.any?(&:failed?) ? :failed : :passed
      world.notify_observers(:scenario_finished, self)
      @scenario = nil # cleanup memory after scenario executon
    end

    def run_step(step)
      return if step.skipped?
      @current_step = step
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

    def metadata
      if current_step
        @metadata.merge(current_step.metadata)
      else
        @metadata
      end
    end
  end
end
