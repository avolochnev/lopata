require 'lopata/id'
require 'lopata/config'
require 'lopata/scenario_builder'
require 'lopata/scenario'
require 'lopata/step'
require 'lopata/shared_step'

module Lopata
  def self.define(*args, &block)
    Lopata::ScenarioBuilder.define(*args, &block)
  end

  # Skip scenario definition. Option to temporary ignore scenario
  def self.xdefine(*args, &block)
  end

  def self.shared_step(name, &block)
    Lopata::SharedStep.register(name, &block)
  end

  def self.configure(&block)
    yield Lopata::Config
  end
end
