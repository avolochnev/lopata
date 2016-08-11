module Lopata
  module Config
    extend self

    attr_accessor :build_number, :lopata_host, :lopata_code, :only_roles, :role_descriptions, :after_as, :ops

    def init(env)
      require 'yaml'
      @config = YAML::load(File.open("./config/environments/#{env}.yml")) || {}
      init_db
      @role_descriptions ||= {}
      # init_includes
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
    end

    def init_active_record
      require 'lopata/rspec/ar_dsl'
      ::RSpec.configure do |c|
        c.include Lopata::RSpec::AR::DSL
      end
    end

    def init_lopata_logging(build)
      self.build_number = build
      ::RSpec.configure do |c|
        require 'lopata/rspec/formatter' # class cross-loading, avoid auto-loading
        c.add_formatter Lopata::RSpec::Formatter
      end
    end

    def before_start(&block)
      @before_start = block
    end

    def initialize_test
      @before_start.call if @before_start
    end
  end
end