module Lopata
  class SharedStep
    attr_reader :block

    class SharedStepNotFound < StandardError; end

    def self.register(name, &block)
      raise ArgumentError, "Comma is not allowed in shared step name: '%s'" % name if name =~ /,/
      @shared_steps ||= {}
      @shared_steps[name] = new(&block)
    end

    def self.find(name)
      @shared_steps[name] or raise StandardError, "Shared step '%s' not found" % name
    end

    def initialize(&block)
      @block = block
    end

    def steps
      @steps ||= build_steps
    end

    def build_steps
      builder = Lopata::ScenarioBuilder.new
      builder.instance_exec(&block)
      builder.steps
    end
  end
end