module Lopata
  class Step
    attr_reader :block, :status, :exception, :args, :condition

    def initialize(method_name, *args, condition: nil, &block)
      @method_name = method_name
      @args = args
      @status = :not_started
      @block = block
      @exception = nil
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
      end
      world.notify_observers(:step_finished, self)
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

    def teardown?
      %i{ teardown cleanup }.include?(@method_name)
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

  end
end