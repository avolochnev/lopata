module Lopata
  # Stores runtime configuration information
  #
  # @see Lopata.configure
  # @see Lopata.configuration
  class Configuration
    # Build an object to store runtime configuration options and set defaults
    def initialize
      @before_start_hooks = []
      @before_scenario_steps = []
      @after_scenario_steps = []
      @observers = [Lopata::Observers::ConsoleOutputObserver.new]
      @role_descriptions = {}
      @env = :qa
    end

    # Add the hook to be called before scenarios running
    # The block will be called after framework initialization and before scenarios parsing.
    # It usually allow to require and initialize the libraries used for project testing.
    #
    # @example
    #     Lopata.configure do |c|
    #       c.before_start do
    #         require 'active_record'
    #       end
    #     end
    def before_start(&block)
      @before_start_hooks << block
    end

    # @private
    def run_before_start_hooks
      @before_start_hooks.each(&:call)
    end

    # Defines 'before scenario' steps.
    # Given steps will be runned before each scenario in context of scenario.
    # It may be shared step names, and|or block.
    #
    # @example
    #     Lopata.configure do |c|
    #       c.before_scenario 'setup test user'
    #     end
    #
    # @param steps [Array<String>] name of shared steps
    # @param block [Proc] block of code
    def before_scenario(*steps, &block)
      before_scenario_steps.append(*steps) unless steps.empty?
      before_scenario_steps.append(block) if block_given?
    end

    # Defines 'after scenario' steps.
    # Given steps will be runned after each scenario in context of scenario.
    # It may be shared step names, and|or block.
    #
    # @example
    #     Lopata.configure do |c|
    #       c.after_scenario 'cleanup test user'
    #     end
    #
    # @param steps [Array<String>] name of shared steps
    # @param block [Proc] block of code
    def after_scenario(*steps, &block)
      after_scenario_steps.append(*steps) unless steps.empty?
      after_scenario_steps.append(block) if block_given?
    end

    # @private
    attr_reader :before_scenario_steps, :after_scenario_steps

    # Add an observer to the set Lopata to be used for this run.
    #
    # @param observer [Lopata::Observers::BaseObserver] a observer instance.
    #
    # @see Lopata::Observers::BaseObserver
    def add_observer(observer)
      @observers << observer
    end

    # @private
    attr_reader :observers

    # @private
    def filters
      @filters ||= []
    end

    # @private
    attr_accessor :web_logging_params

    # @private
    def init_lopata_logging(url, project_code, build_number)
      require 'lopata/observers/web_logger'
      self.web_logging_params = { url: url, project_code: project_code, build_number: build_number }
      add_observer Lopata::Observers::WebLogger.new
    end

    # @return [Hash{Symbol => String}] map or role codes to role name.
    # @see Lopata::Role
    attr_accessor :role_descriptions

    # @return [Symbol,nil] user role to be used in scenario if not specified
    # @see Lopata::Role
    attr_accessor :default_role

    # @return [Symbol] environment code.
    #   Default is :qa
    # @see Lopata::Environment
    attr_accessor :env

    # @return [Boolean] keep generated test data after scenarios running.
    #   Default is false
    #   Set to true for keeping generated data.
    #   Use 'lopata --keep' modifier to set keep mode on running.
    # @see Lopata::ActiveRecord::Methods#cleanup
    attr_accessor :keep

    # @private
    attr_accessor :environment

    # @private
    def load_environment
      self.environment = Lopata::Environment.new(env)
    end
  end
end