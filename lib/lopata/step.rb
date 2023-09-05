require 'forwardable'

module Lopata
  # @private
  class Step
    attr_reader :block, :args, :condition, :method_name, :shared_step
    # metadata overrien by the step.
    attr_accessor :metadata

    def initialize(method_name, *args, condition: nil, shared_step: nil, &block)
      @method_name = method_name
      @args = args
      @block = block
      @shared_step = shared_step
      @condition = condition
      initialized! if defined? initialized!
    end

    def title
      base_title = args.first
      base_title ||= shared_step && "#{method_name.capitalize} #{shared_step.name}" || "Untitled #{method_name}"
      base_title
    end

    def execution_steps(scenario, groups: [])
      return [] if condition && !condition.match?(scenario)
      return [] unless block
      [StepExecution.new(self, groups, condition: condition, &block)]
    end
  end

  # @private
  # Used for action, setup, teardown, verify
  class ActionStep < Step
    def execution_steps(scenario, groups: [])
      steps = []
      return steps if condition && !condition.match?(scenario)
      convert_args(scenario).each do |step|
        if step.is_a?(String)
          Lopata::SharedStep.find(step).steps.each do |shared_step|
            next if shared_step.condition && !shared_step.condition.match?(scenario)
            shared_group = SharedGroupStep.new(:shared_step)
            steps += shared_step.execution_steps(scenario, groups: groups + [shared_group])
          end
        elsif step.is_a?(Proc)
          steps << StepExecution.new(self, groups, condition: condition, &step)
        end
      end
      steps << StepExecution.new(self, groups, condition: condition, &block) if block
      steps.reject { |s| !s.block }
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

    def execution_steps(scenario, groups: [])
      steps = []
      return steps if condition && !condition.match?(scenario)
      @steps.each do |step|
        steps += step.execution_steps(scenario, groups: groups + [self])
      end
      steps.reject! { |s| !s.block }
      steps.reject { |s| s.teardown_group?(self) } + steps.select { |s| s.teardown_group?(self) }
    end

    def let_methods
      @let_methods ||= {}
    end

    def let_bang_methods 
      @let_bang_methods ||= {}
    end

    private

    # Group step's block is a block in context of builder, not scenario. So hide the @block to not be used in scenario.
    def initialized!
      builder = Lopata::ScenarioBuilder.new(title)
      builder.instance_exec(&@block)
      @steps = builder.steps
      @block = nil
    end
  end

  # @private
  # Fake group for shared step instance
  # Used to build group hierarhy including chared steps
  class SharedGroupStep < Step
    # stub title - should not be used in scenario/step name generation.
    def title 
      ''
    end
  end

  #@private
  class StepExecution
    attr_reader :step, :status, :exception, :block, :pending_message, :groups, :condition
    extend Forwardable
    def_delegators :step, :method_name

    class PendingStepFixedError < StandardError; end

    def initialize(step, groups, condition: nil, &block)
      @step = step
      @status = :not_runned
      @exception = nil
      @block = block
      @groups = groups
      @condition = condition
    end

    def title
      "#{group_title}#{step.title}"
    end

    def group_title
      groups.map { |g| "#{g.title}: " }.join
    end

    def run(scenario)
      @status = :running
      begin
        unless check_dynamic_condition?(scenario)
          @status = :ignored
          return
        end
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

    def check_dynamic_condition?(scenario)
      dynamic_conditions.each do
        return false unless _1.match_dynamic?(scenario)
      end
      true
    end

    def dynamic_conditions
      conds = []
      conds << condition if condition&.dynamic?
      groups.each do
        conds << _1.condition if _1.condition&.dynamic?
      end
      conds
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

    def pending?
      status == :pending
    end

    def pending!(message = nil)
      @status = :pending
      @pending_message = message
    end

    # Need log this step.
    def loggable?
      return false if ignored?
      not %i{ let let! }.include?(method_name)
    end

    def teardown?
      %i{ teardown cleanup }.include?(method_name)
    end

    def teardown_group?(group = nil)
      teardown? && self.groups.last == group
    end

    def in_group?(group)
      groups.include?(group)
    end

    def skip_rest_on_failure?
      %i{ setup action }.include?(method_name)
    end

    # Step metadata is a combination of metadata given for step and all contexts (groups) the step included
    def metadata
      (groups + [step]).compact.inject({}) { |merged, part| merged.merge(part.metadata) }
    end

    # Step methods is a combination of let_methods for all contexts (group) the step included
    def let_methods
      (groups).compact.inject({}) { |merged, part| merged.merge(part.let_methods) }
    end

    # Step bang methods is a combination of let_bang_methods for all contexts (group) the step included
    def let_bang_methods
      (groups).compact.inject({}) { |merged, part| merged.merge(part.let_bang_methods) }
    end
  end
end
