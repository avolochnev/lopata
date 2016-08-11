require 'thor'
require_relative 'generators/app'
require_relative 'config'

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
    def test
      require 'rspec'

      Dir["./spec/support/**/*.rb"].sort.each { |f| require f}
      ENV['HOME'] = File.absolute_path('.') # disable warning on rspec loading on windows
      Lopata::Config.ops = {
        focus: options[:focus],
        rerun: options[:rerun],
        users: options[:users],
        build: options[:build],
        env:   options[:env],
        keep:  options[:keep]
      }
      Lopata::Config.init(options[:env])
      Lopata::Config.initialize_test
      Lopata::Config.init_rspec

      ::RSpec::Core::Runner.run ['spec']
    end

    default_task :test

    register Generators::App, :new, 'lopata new project-name', 'Init new lopata projects'
  end
end

unless ARGV.first == 'new'
  raise 'No Lopatafile found in running dir' unless File.exists?('./Lopatafile')
  eval File.binread('./Lopatafile')
end

