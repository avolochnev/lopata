require 'lopata/id'
require 'lopata/config'
require 'lopata/scenario'

module Lopata
  def self.define(*args, &block)
    Lopata::Scenario.define(*args, &block)
  end

  def self.xdefine(*args, &block)
    Lopata::Scenario.xdefine(*args, &block)
  end
end
