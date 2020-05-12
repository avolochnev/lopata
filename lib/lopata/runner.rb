require 'thor'
require_relative 'generators/app'
require_relative 'config'
require_relative 'world'
require_relative '../lopata'
require_relative 'observers'

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

      # Dir["./spec/support/**/*.rb"].sort.each { |f| require f}
      world = Lopata::Config.world
      world.setup_observers
      world.load_shared_steps
      world.load_scenarios(*args)
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
          rerun: options[:rerun],
          users: options[:users],
          build: options[:build],
          env:   options[:env],
          keep:  options[:keep],
          text:  options[:text]
        }
        Lopata::Config.init(options[:env])
        Lopata::Config.initialize_test
        # ENV['HOME'] = File.absolute_path('.') # disable warning on rspec loading on windows
        # Lopata::Config.init_rspec
      end
    end
  end
end

unless ARGV.first == 'new'
  eval File.binread('./Lopatafile') if File.exists?('./Lopatafile')
end

