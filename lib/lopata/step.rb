module Lopata
  class Step
    attr_reader :block, :status, :exception, :args, :condition, :method_name, :shared_step

    def initialize(method_name, *args, condition: nil, shared_step: nil, &block)
      @method_name = method_name
      @args = args
      @status = :not_runned
      @block = block
      @exception = nil
      @shared_step = shared_step
      @condition = condition || Lopata::Condition::EMPTY
    end

    def run(scenario)
      @status = :running
      world.notify_observers(:step_started, self)
      begin
        run_step(scenario)
        @status = :passed
      rescue Exception => e
        @status = :failed
        @exception = e
        scenario.skip_rest if skip_rest_on_failure?
      end
      world.notify_observers(:step_finished, self)
    end

    def title
      args.first || shared_step && "#{method_name.capitalize} #{shared_step.name}" || "Untitled #{method_name}"
    end

    def run_step(scenario)
      scenario.instance_exec(&block) if block
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

    def teardown?
      %i{ teardown cleanup }.include?(@method_name)
    end

    def skip_rest_on_failure?
      %i{ setup action }.include?(@method_name)
    end

    def pre_steps(scenario)
      []
    end
  end

  # Used for action, setup, teardown
  class ActionStep < Step
    def pre_steps(scenario)
      steps = []
      convert_args(scenario).each do |step|
        if step.is_a?(String)
          Lopata::SharedStep.find(step).steps.each do |shared_step|
            steps += shared_step.pre_steps(scenario)
            steps << shared_step
          end
        elsif step.is_a?(Proc)
          steps << Lopata::Step.new(method_name, &step)
        end
      end
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
end
