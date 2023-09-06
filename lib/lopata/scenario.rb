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
    attr_reader :scenario, :status, :title, :current_step, :top

    def initialize(title, options_title, metadata = {})
      @title = [title, options_title].compact.reject(&:empty?).join(' ')
      @let_methods = {}
      @status = :not_runned
      @scenario = Lopata::Scenario.new(self)
      @top = Lopata::GroupExecution.new(Lopata::TopStep.new(metadata: metadata), nil, steps: [])
    end

    # Provide a human-readable representation of this class
    def inspect
      "#<#{self.class.name} #{title.inspect}>"
    end
    alias to_s inspect

    def steps
      top.steps
    end

    def run
      @status = :running
      world.notify_observers(:scenario_started, self)
      @status = run_step(top)
      # @status = top.steps.any?(&:failed?) ? :failed : :passed
      world.notify_observers(:scenario_finished, self)
      cleanup
    end

    def run_step(step)
      @current_step = step
      return :skipped if step.skipped?
      return :ignored if step.ignored?
      if step.condition&.dynamic && !step.condition.match_dynamic?(scenario)
        step.ignored!
        return :ignored
      end
      if step.group?
        skip_rest = false
        step.steps.each do
          if _1.teardown?
            run_step(_1)
          elsif skip_rest
            _1.skip!
          else
            run_step(_1)
            skip_rest = true if _1.failed? && _1.skip_rest_on_failure?
          end 
        end
        step.status!
      else
        step.run(scenario)
        step.status
      end
    end

    def world
      Lopata.world
    end

    def failed?
      status == :failed
    end

    def metadata
      current_step&.metadata || top.metadata
    end

    def let_methods
      if current_step
        @let_methods.merge(current_step.let_methods)
      else
        @let_methods
      end
    end

    def let_base
      if current_step && current_step.parent
        current_step.parent.step.let_methods
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
