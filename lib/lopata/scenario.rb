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

  # Provide a human-readable representation of this class
  def inspect
    "#<#{self.class.name} #{execution.title.inspect}>"
  end
  alias to_s inspect

  

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

  private

  # @private
  def method_missing(method, *args, &block)
    if execution.let_methods.include?(method)
      execution.let_methods[method].call_in_scenario(self, *args)
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

    # Provide a human-readable representation of this class
    def inspect
      "#<#{self.class.name} #{title.inspect}>"
    end
    alias to_s inspect

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

    def let_base
      if current_step && !current_step.groups.empty?
        current_step.groups.last.let_methods
      else
        @let_methods
      end
    end

    def let(method_name, &block)
      let_base[method_name] = LetMethod.new(&block)
    end

    def let!(method_name, &block)
      let_base[method_name] = LetBangMethod.new(&block)
    end

    def cleanup
      @title = nil
      @metadata = nil
      @steps = nil
      @scenario = nil
    end
  end

  # @private
  # let! methods incapsulate cached value and calculation block
  class LetBangMethod
    attr_reader :block, :calculated, :value

    alias calculated? calculated

    def initialize(&block)
      @block = block
      @calculated = false
      @value = nil
    end

    def call_in_scenario(scenario, *args)
      if calculated?
        value
      else
        @value = scenario.instance_exec(&block)
        @calculated = true
        @value
      end
    end
  end

  # @private
  # let methods calculates 
  class LetMethod
    attr_reader :block

    def initialize(&block)
      @block = block
    end

    def call_in_scenario(scenario, *args)
      scenario.instance_exec(*args, &block)
    end
  end
end
