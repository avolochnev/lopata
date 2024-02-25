require 'forwardable'

module Lopata
  # @private
  class Step
    attr_reader :block, :args, :condition, :method_name, :shared_step
    # metadata overrien by the step.
    attr_accessor :metadata

    def initialize(method_name, *args, condition: nil, shared_step: nil, metadata: {}, &block)
      @method_name = method_name
      @args = args
      @block = block
      @shared_step = shared_step
      @condition = condition
      @metadata = metadata
      initialized! if defined? initialized!
    end

    def title
      base_title = args.first
      base_title ||= shared_step && "#{method_name.capitalize} #{shared_step.name}" || "Untitled #{method_name}"
      base_title
    end

    def execution_steps(scenario, parent:)
      return [] if condition && !condition.match?(scenario)
      return [] unless block
      [StepExecution.new(self, parent, condition: condition, &block)]
    end
  end

  # @private
  # Used for action, setup, teardown, verify
  class ActionStep < Step
    def execution_steps(scenario, parent:)
      steps = []
      return steps if condition && !condition.match?(scenario)
      convert_args(scenario).each do |step|
        if step.is_a?(String)
          Lopata::SharedStep.find(step).steps.each do |shared_step|
            next if shared_step.condition && !shared_step.condition.match?(scenario)
            steps += shared_step.execution_steps(scenario, parent: parent)
          end
        elsif step.is_a?(Proc)
          steps << StepExecution.new(self, parent, condition: condition, &step)
        end
      end
      steps << StepExecution.new(self, parent, condition: condition, &block) if block
      steps
    end

    def separate_args(args)
      args.map { |a| a.is_a?(String) && a =~ /,/ ? a.split(',').map(&:strip) : a }.flatten
    end

    def convert_args(scenario)
      flat_args = separate_args(args.flatten)
      flat_args.map do |arg|
        case arg
          # trait symbols as link to metadata.
          when Symbol then scenario.metadata[arg]
        else
          arg
        end
      end.flatten
    end

    def title
      shared_step && "#{method_name.capitalize} #{shared_step.name}" || "Untitled #{method_name}"
    end
  end

  # @private
  # Used for context
  class GroupStep < Step

    def execution_steps(scenario, parent: nil)
      steps = []
      return steps if condition && !condition.match?(scenario)
      group = GroupExecution.new(self, parent, steps: steps, condition: condition)
      @steps.each do |step|
        steps += step.execution_steps(scenario, parent: group)
      end
      group.steps.push(*steps.reject(&:teardown?))
      group.steps.push(*steps.select(&:teardown?))
      [group]
    end

    # Group step's block is a block in context of builder, not scenario. So hide the @block to not be used in scenario.
    def initialized!
      builder = Lopata::ScenarioBuilder.new(title)
      builder.instance_exec(&@block)
      @steps = builder.steps
      @block = nil
    end
  end

  # @private
  class TopStep < Step
    def initialize(title, metadata: {})
      super(:top, title, metadata: metadata)
    end
 end

  # @private
  # Abstract execution step. Composition, may be group or step.
  class BaseExecution
    attr_reader :step, :status, :parent, :condition
    extend Forwardable
    def_delegators :step, :method_name

    def initialize(step, parent, condition: nil)
      @step = step
      @parent = parent
      @condition = condition
      reset_status
    end

    def reset_status
      @status = :not_runned
    end

    def group?
      false
    end

    def top?
      !parent
    end

    def teardown?
      %i{ teardown cleanup }.include?(method_name)
    end

    def parents
      result = []
      prnt = parent
      while prnt
        result << prnt
        prnt = prnt.parent
      end
      result
    end

     # Step metadata is a combination of metadata given for step and all contexts (groups) the step included
    def metadata
      result = step.metadata || {}
      if parent
        result = parent.metadata.merge(result)
      end
      result
    end

    def find_let_method(name)
      parent&.find_let_method(name)
    end

    def failed?
      status == :failed
    end

    def passed?
      status == :passed
    end

    def skipped?
      status == :skipped
    end

    def ignored?
      status == :ignored
    end

    def ignored!
      status == :ignored
    end

    def skip!
      @status = :skipped
    end

    def title
      if parent && !parent.top?
        "#{parent.title}: #{step.title}"
      else
        step.title
      end
    end

    # Need log this step.
    def loggable?
      return false if ignored?
      not %i{ let let! }.include?(method_name)
    end

    def skip_rest_on_failure?
      %i{ setup action }.include?(method_name)
    end
  end

  # @private
  class GroupExecution < BaseExecution
    attr_reader :steps

    def initialize(step, parent, condition: nil, steps:)
      super(step, parent, condition: condition)
      @steps = steps
      @let_methods = {}
    end

    def reset_status
      super
      return unless @steps
      @steps.each(&:reset_status)
    end

    def group?
      true
    end

    def status!
      # return @status if @status
      statuses = steps.map(&:status!).uniq
      @status = 
        if statuses.length == 1
          statuses.first
        elsif statuses.include?(:failed)
          :failed
        else
          statuses.first || :skipped
        end
      @status = :passed if @status == :pending
      @status
    end

    def find_let_method(name)
      @let_methods[name] || parent&.find_let_method(name)
    end

    def add_let_method(name, method)
      @let_methods[name] = method
    end

    def ignored!
      @status = :ignored
      steps.each(&:ignored!)
    end
  end

  # @private
  class StepExecution < BaseExecution
    attr_reader :exception, :block, :pending_message

    class PendingStepFixedError < StandardError; end

    def initialize(step, parent, condition: nil, &block)
      super(step, parent, condition: condition)
      @exception = nil
      @block = block
    end

    alias status! status

    def run(scenario)
      @status = :running
      begin
        run_step(scenario)
        if pending?
          @status = :failed
          raise PendingStepFixedError, 'Expected step to fail since it is pending, but it passed.'
        else
          @status = :passed
        end
      rescue Exception => e
        @status = :failed unless pending?
        @exception = e
      end
    end

    def run_step(scenario)
      return unless block
      scenario.instance_exec(&block)
    end

    def pending?
      status == :pending
    end

    def pending!(message = nil)
      @status = :pending
      @pending_message = message
    end
  end
end
