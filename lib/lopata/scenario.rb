require 'rspec/expectations'

# Scenario runtime class.
#
# All the scenarios are running in context of separate Lopata::Scenario object.
#
class Lopata::Scenario
  include RSpec::Matchers

  # @private
  attr_reader :execution

  # @private
  def initialize(execution)
    @execution = execution
  end

  # Marks current step as pending
  # @example
  #     it 'pending step' do
  #       pending
  #       expect(1).to eq 2
  #     end
  #
  # Pending steps wont be failed
  def pending(message = nil)
    execution.current_step.pending!(message)
  end

  # @return [Hash] metadata available for current step
  # @note The metadata keys also availalbe as methods (via method_missing)
  def metadata
    execution.metadata
  end

  # @private
  def to_s
    %Q{<Lopata::Scenario:"#{execution.title}">}
  end

  private

  # @private
  def method_missing(method, *args, &block)
    if execution.let_methods.include?(method)
      instance_exec(*args, &execution.let_methods[method])
    elsif metadata.keys.include?(method)
      metadata[method]
    else
      super
    end
  end

  # @private
  def respond_to_missing?(method, *)
    execution.let_methods.include?(method) or metadata.keys.include?(method) or super
  end

  # @private
  # Scenario execution and live-cycle information
  class Execution
    attr_reader :scenario, :status, :steps, :title, :current_step

    def initialize(title, options_title, metadata = {})
      @title = [title, options_title].compact.reject(&:empty?).join(' ')
      @metadata = metadata
      @let_methods = {}
      @status = :not_runned
      @steps = []
      @scenario = Lopata::Scenario.new(self)
    end

    def run
      @status = :running
      sort_steps
      world.notify_observers(:scenario_started, self)
      steps.each(&method(:run_step))
      @status = steps.any?(&:failed?) ? :failed : :passed
      world.notify_observers(:scenario_finished, self)
      cleanup
    end

    def run_step(step)
      return if step.skipped?
      @current_step = step
      step.run(scenario)
      skip_rest if step.failed? && step.skip_rest_on_failure?
      @current_step = nil
    end

    def world
      Lopata.world
    end

    def failed?
      status == :failed
    end

    def sort_steps
      @steps = steps.reject(&:teardown_group?) + steps.select(&:teardown_group?)
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

    def let_methods
      if current_step
        @let_methods.merge(current_step.let_methods)
      else
        @let_methods
      end
    end

    def let(method_name, &block)
      # define_singleton_method method_name, &block
      base =
        if current_step && !current_step.groups.empty?
          current_step.groups.last.let_methods
        else
          @let_methods
        end
      base[method_name] = block
    end

    def cleanup
      @title = nil
      @metadata = nil
      @steps = nil
      @scenario = nil
    end
  end
end
