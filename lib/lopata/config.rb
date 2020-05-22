module Lopata
  module Config
    extend self

    attr_accessor :build_number, :lopata_host, :lopata_code, :only_roles, :role_descriptions,
                  :default_role, :ops

    def init(env)
      require 'yaml'
      @config = {}
      config_filename = "./config/environments/#{env}.yml"
      @config = YAML::load(File.open(config_filename)) if File.exists?(config_filename)
      init_db
      @role_descriptions ||= {}
      # init_includes
    end

    def [](key)
      @config[key]
    end

    %w{url name readonly}.each do |opt|
      define_method opt do
        raise "Lopata::Config unititlalized, use Lopata::Config#init(env) to set environment" unless @config
        @config[opt]
      end
    end

    def init_db
      ActiveRecord::Base.establish_connection(@config['db']) if @config['db']
    end

    def init_rspec
      require 'lopata/rspec/dsl'
      require 'lopata/rspec/role'
      ::RSpec.configure do |c|
        c.include Lopata::RSpec::DSL
        c.include Lopata::RSpec::Role
      end
      init_rspec_filters
    end

    def init_lopata_logging(build)
      self.build_number = build
      require 'lopata/observers/web_logger'
      add_observer Lopata::Observers::WebLogger.new
    end

    def init_rspec_filters
      filters = {}
      filters[:focus] = true if ops[:focus]
      unless filters.blank?
        ::RSpec.configure do |c|
          c.inclusion_filter = filters
        end
      end
    end

    def before_start(&block)
      @before_start = block
    end

    def before_scenario(*steps, &block)
      before_scenario_steps.append(*steps) unless steps.empty?
      before_scenario_steps.append(block) if block_given?
    end

    def before_scenario_steps
      @before_scenario_steps ||= []
    end

    def after_scenario(*steps, &block)
      after_scenario_steps.append(*steps) unless steps.empty?
      after_scenario_steps.append(block) if block_given?
    end

    def after_scenario_steps
      @after_scenario_steps ||= []
    end

    def initialize_test
      @before_start.call if @before_start
    end

    def world
      @world ||= Lopata::World.new
    end

    def filters
      @filters ||= []
    end

    def add_observer(observer)
      world.observers << observer
    end
  end
end