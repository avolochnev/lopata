module Lopata
  class Step
    attr_reader :block, :status, :exception

    def initialize(method_name, *args, &block)
      @method_name = method_name
      @args = args
      @status = :not_started
      @block = block
      @exception = nil
    end

    def run(scenario)
      @status = :running
      world.notify_observers(:step_started, self)
      begin
        scenario.instance_exec(&block)
        @status = :passed
      rescue Exception => e
        @status = :failed
        @exception = e
      end
      world.notify_observers(:step_finished, self)
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
  end
end