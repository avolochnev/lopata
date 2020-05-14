module Lopata
  class SharedStep
    attr_reader :name, :block

    class SharedStepNotFound < StandardError; end

    def self.register(name, &block)
      raise ArgumentError, "Comma is not allowed in shared step name: '%s'" % name if name =~ /,/
      @shared_steps ||= {}
      @shared_steps[name] = new(name, &block)
    end

    def self.find(name)
      @shared_steps[name] or raise StandardError, "Shared step '%s' not found" % name
    end

    def initialize(name, &block)
      @name, @block = name, block
    end

    def steps
      @steps ||= build_steps
    end

    def build_steps
      builder = Lopata::ScenarioBuilder.new(name)
      builder.shared_step = self
      builder.instance_exec(&block)
      builder.steps
    end
  end
end