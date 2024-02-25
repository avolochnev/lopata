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

    if (let_method = execution.find_let_method(method))
      let_method.call_in_scenario(self, *args)
    elsif metadata.keys.include?(method)
      metadata[method]
    else
      super
    end
  end

  # @private
  def respond_to_missing?(method, *)
    execution.find_let_method(method) or metadata.keys.include?(method) or super
  end

  # @private
  # Scenario execution and live-cycle information
  class Execution
    attr_reader :scenario, :current_step, :top, :title, :base_metadata

    def initialize(title, metadata = {})
      @title = title
      @base_metadata = metadata
      @top = Lopata::GroupExecution.new(Lopata::TopStep.new(title, metadata: base_metadata), nil, steps: [])
      setup
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
      unless @scenario # for second run if need
        setup
        top.reset_status
      end
      world.notify_observers(:scenario_started, self)
      run_step(top)
      world.notify_observers(:scenario_finished, self)
      cleanup
    end

    def setup
      @scenario = Lopata::Scenario.new(self)
      @current_step = @top
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
      current_step.metadata
    end

    def let_methods
      current_step.let_methods
    end

    def find_let_method(name)
      current_step.find_let_method(name)
    end

    def status
      top.status
    end

    def let_base
      if current_step.group?
        current_step
      else
        current_step.parent
      end
    end

    def let(method_name, &block)
      let_base.add_let_method(method_name, LetMethod.new(&block))
    end

    def let!(method_name, &block)
      let_base.add_let_method(method_name, LetBangMethod.new(&block))
    end

    def cleanup
      @scenario = nil
      @current_step = nil
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
