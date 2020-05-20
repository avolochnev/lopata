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
      world.scenarios.each { |s| s.execution.run }
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
          rerun: options[:rerun],
          users: options[:users],
          build: options[:build],
          env:   options[:env],
          keep:  options[:keep],
          text:  options[:text]
        }
        Lopata::Config.init(options[:env])
        Lopata::Config.initialize_test
      end
    end
  end
end

unless ARGV.first == 'new'
  eval File.binread('./Lopatafile') if File.exists?('./Lopatafile')
end

