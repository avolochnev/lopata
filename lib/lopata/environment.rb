module Lopata
  # Settings of test enviromnet the scenarios to be runned.
  #
  # Lopata allows to define different environments the scenarios to be runned on.
  # Set environment name via command line 'lopata -e stage' or via configuration:
  #
  #     Lopata.configure do |c|
  #       c.env = :stage
  #     end
  #
  # The environment params are loaded from './config/environments/<env>.yml'.
  class Environment
    # Loads environment configuration for given env
    # @param env [Symbol] environment key
    #    Loads golobl configured environment if not given.
    # @see Lopata::Configuration#env
    def initialize(env = Lopata.configuration.env)
      require 'yaml'
      @config = {}
      config_filename = "./config/environments/#{Lopata.configuration.env}.yml"
      @config = YAML::load(File.open(config_filename)) if File.exist?(config_filename)
    end

    # Access to environment settings
    # @param key [Symbol] environment configuration key is set on yml configuration.
    def [](key)
      @config[key]
    end

    %w{url}.each do |opt|
      define_method opt do
        @config[opt]
      end
    end
  end
end
