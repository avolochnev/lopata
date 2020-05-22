require 'thor'
require_relative 'generators/app'
require_relative 'config'
require_relative 'world'
require_relative 'loader'
require_relative '../lopata'
require_relative 'observers'
require_relative 'condition'

module Lopata
  class Runner < Thor
    desc 'test', 'Run tests'
    option :env, default: :qa, aliases: 'e'
    option :"no-log", type: :boolean, aliases: 'n'
    option :focus, type: :boolean, aliases: 'f'
    option :rerun, type: :boolean, aliases: 'r'
    option :users, type: :array, aliases: 'u'
    option :build, aliases: 'b'
    option :keep, type: :boolean, aliases: 'k'
    option :text, aliases: 't'
    def test(*args)
      configure_from_options
      Lopata::Loader.load_shared_steps
      Lopata::Loader.load_scenarios(*args)
      world = Lopata::Config.world
      world.start
      world.scenarios.each { |s| s.run }
      world.finish
    end

    default_task :test

    register Generators::App, :new, 'lopata new project-name', 'Init new lopata projects'

    def self.exit_on_failure?
      true
    end

    no_commands do
      def configure_from_options
        Lopata::Config.ops = {
          focus: options[:focus],
          users: options[:users],
          build: options[:build],
          env:   options[:env],
          keep:  options[:keep],
        }
        Lopata::Config.init(options[:env])
        Lopata::Config.initialize_test
        add_text_filter(options[:text]) if options[:text]
        add_rerun_filter if options[:rerun]
      end

      def add_text_filter(text)
        Lopata::Config.filters << -> (scenario) { scenario.title.include?(text) }
      end

      def add_rerun_filter
        to_rerun = Lopata::Client.new(Lopata::Config.build_number).to_rerun
        puts to_rerun
        Lopata::Config.filters << -> (scenario) { to_rerun.include?(scenario.title) }
      end
    end
  end
end

unless ARGV.first == 'new'
  eval File.binread('./Lopatafile') if File.exists?('./Lopatafile')
end

