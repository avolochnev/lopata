require 'lopata/id'
require 'lopata/config'
require 'lopata/scenario_builder'
require 'lopata/scenario'
require 'lopata/step'
require 'lopata/shared_step'

module Lopata
  # Define the scenario.
  # @see Lopata::ScenarioBuilder#define
  def self.define(*args, &block)
    Lopata::ScenarioBuilder.define(*args, &block)
  end

  # Skip scenario definition. Option to temporary ignore scenario
  def self.xdefine(*args, &block)
  end

  # Register the shared step
  #
  # @example
  #     Lopata.shared_step 'test user' do
  #       setup { @user = create(:user) }
  #     end
  #
  # Shared step may be used in scenarios by name:
  # @example
  #     Lopata.define 'user' do
  #       setup 'test user'
  #
  #       it 'exists' do
  #         expect(@user).to_not be_nil
  #       end
  #     end
  # @param name [String] shared step unique name
  # @param block shared step action sequence definition
  def self.shared_step(name, &block)
    Lopata::SharedStep.register(name, &block)
  end

  # Yields the global configuration to a block.
  # @yield [Lopata::Config] global configuration
  #
  # @example
  #     Lopata.configure do |config|
  #       config.add_formatter 'documentation'
  #     end
  # @see Core::Configuration
  def self.configure(&block)
    yield Lopata::Config
  end
end
