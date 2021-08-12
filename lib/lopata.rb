require 'lopata/id'
require 'lopata/configuration'
require 'lopata/environment'
require 'lopata/scenario_builder'
require 'lopata/scenario'
require 'lopata/step'
require 'lopata/shared_step'

# Namespace for all Lopata code.
module Lopata
  # Define the scenario.
  # @see Lopata::ScenarioBuilder.define
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
  # @param block [Block] shared step action sequence definition
  def self.shared_step(name, &block)
    Lopata::SharedStep.register(name, &block)
  end

  # Register the shared step for setup.
  # 
  # shared_setup is a shortcat for shared_step 'name' { setup { .. } }. The block will be arrounded into the setup call.
  #
  # @example
  #     Lopata.shared_setup 'test user' do
  #       @user = create(:user)
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
  # @param block [Block] shared setup definition
  def self.shared_setup(name, &block)
    Lopata::SharedStep.register(name) do
      setup(&block)
    end
  end

  # Register the shared step for context.
  # 
  # shared_context is a shortcat for shared_step('name') { context('name') { .. } }. The block will be arrounded into the context call.
  #
  # @example
  #     Lopata.shared_context 'calculation' do
  #       it('correct') { expect(1 + 1).to eq 2 }
  #       it('incorrect') { expect(1 + 2).to eq 4 }
  #     end
  #
  # Shared context may be used in scenarios by name:
  # @example
  #     Lopata.define 'verify calcuation in context' do
  #       verify 'calculation'
  #     end
  # @param name [String] shared step unique name, will be used as a context's name
  # @param block [Block] shared context definition
  def self.shared_context(name, &block)
    Lopata::SharedStep.register(name) do
      context(name, &block)
    end
  end

  # Yields the global configuration to a block.
  # @yield [Lopata::Configuration] global configuration
  #
  # @example
  #     Lopata.configure do |config|
  #       config.before_scenario 'setup test user'
  #     end
  # @see Lopata::Configuration
  def self.configure(&block)
    yield Lopata.configuration
  end

  # Returns global configuration object.
  # @return [Lopata::Configuration]
  # @see Lopata.configure
  def self.configuration
    @configuration ||= Lopata::Configuration.new
  end

  # @private
  # Internal container for global non-configuration data.
  def self.world
    @world ||= Lopata::World.new
  end

  # Return global environment object
  # @return [Lopata::Environment]
  # @see Lopata::Environment
  def self.environment
    Lopata.configuration.environment
  end
end
