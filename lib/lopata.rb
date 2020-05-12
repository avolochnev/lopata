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

  def self.xdefine(*args, &block)
    Lopata::ScenarioBuilder.xdefine(*args, &block)
  end

  def self.shared_step(name, &block)
    Lopata::SharedStep.register(name, &block)
  end
end
