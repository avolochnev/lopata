module Lopata
  class Step
    attr_reader :block, :args, :condition, :method_name, :shared_step, :group
    # metadata overrien by the step.
    attr_accessor :metadata

    def initialize(method_name, *args, condition: nil, shared_step: nil, group: nil, &block)
      @method_name = method_name
      @args = args
      @block = block
      @shared_step = shared_step
      @condition = condition
      @group = group
      initialized! if defined? initialized!
    end

    def title
      base_title = args.first
      base_title ||= shared_step && "#{method_name.capitalize} #{shared_step.name}" || "Untitled #{method_name}"
      if group
        "#{group.title}: #{base_title}"
      else
        base_title
      end
    end

    def execution_steps(scenario, groups: [])
      return [] if condition && !condition.match?(scenario)
      return [] unless block
      [StepExecution.new(self, groups, &block)]
    end
  end

  # Used for action, setup, teardown
  class ActionStep < Step
    def execution_steps(scenario, groups: [])
      steps = []
      return steps if condition && !condition.match?(scenario)
      convert_args(scenario).each do |step|
        if step.is_a?(String)
          Lopata::SharedStep.find(step).steps.each do |shared_step|
            next if shared_step.condition && !shared_step.condition.match?(scenario)
            steps += shared_step.execution_steps(scenario, groups: groups)
          end
        elsif step.is_a?(Proc)
          steps << StepExecution.new(self, groups, &step)
        end
      end
      steps << StepExecution.new(self, groups, &block) if block
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
      if group
        "%s: %s" % [group.title, method_name]
      else
        shared_step && "#{method_name.capitalize} #{shared_step.name}" || "Untitled #{method_name}"
      end
    end
  end

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

    private

    # Group step's block is a block in context of builder, not scenario. So hide the @block to not be used in scenario.
    def initialized!
      builder = Lopata::ScenarioBuilder.new(title)
      builder.group = self
      builder.instance_exec(&@block)
      @steps = builder.steps
      @block = nil
    end
  end

  class StepExecution
    attr_reader :step, :status, :exception, :block, :pending_message, :groups
    extend Forwardable
    def_delegators :step, :title, :method_name

    class PendingStepFixedError < StandardError; end

    def initialize(step, groups, &block)
      @step = step
      @status = :not_runned
      @exception = nil
      @block = block
      @groups = groups
    end

    def run(scenario)
      @status = :running
      world.notify_observers(:step_started, self)
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
      world.notify_observers(:step_finished, self)
    end

    def run_step(scenario)
      return unless block
      scenario.instance_exec(&block)
    end

    def world
      @world ||= Lopata::Config.world
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

    def teardown?
      %i{ teardown cleanup }.include?(method_name)
    end

    def teardown_group?(group = nil)
      teardown? && self.groups.last == group
    end

    def skip_rest_on_failure?
      %i{ setup action }.include?(method_name)
    end

    # Step metadata is a combination of metadata given for step and all contexts (groups) the step included
    def metadata
      ([step] + groups).compact.inject({}) { |merged, part| merged.merge(part.metadata) }
    end
  end
end
