require 'thor'
require_relative 'generators/app'
require_relative 'world'
require_relative 'loader'
require_relative '../lopata'
require_relative 'observers'
require_relative 'condition'

module Lopata
  # @private
  class Runner < Thor
    class_option :env, default: :qa, aliases: 'e'
    class_option :keep, type: :boolean, aliases: 'k'

    desc 'test', 'Run tests'
    option :rerun, type: :boolean, aliases: 'r'
    option :text, aliases: 't'
    option :list, type: :boolean, aliases: 'l'
    option :init, type: :boolean, aliases: 'i'
    def test(*args)
      trap_interrupt
      configure_from_options
      add_text_filter(options[:text]) if options[:text]
      add_rerun_filter if options[:rerun]
      Lopata::Loader.load_shared_steps
      Lopata::Loader.load_scenarios(*args)
      if options[:list]
        list_scenarios
      elsif options[:init]
        init_scenarios
      else
        run_scenarios
      end
    end

    desc 'suspect', 'Run suspect and not started tests'
    option :skip, type: :numeric, default: 0, aliases: 's'
    option :count, type: :numeric, default: 10, aliases: 'c'
    def suspect(*args)
      trap_interrupt
      configure_from_options
      Lopata::Loader.load_shared_steps
      Lopata::Loader.load_scenarios(*args)
      count = options[:count]
      skip = options[:skip]
      loop do
        need_run = Lopata::Client.new.need_run
        need_run = need_run[skip, count]
        break if need_run.nil?
        world = Lopata::World.new
        world.scenarios.concat(Lopata.world.scenarios.select { |s| need_run.include?(s.title) })
        break if world.scenarios.empty?
        world.notify_observers(:started, world)
        world.scenarios.each { |s| s.run }
        world.notify_observers(:finished, world)
      end
    end

    default_task :test

    register Generators::App, :new, 'new [project-name]', 'Init new lopata projects'

    def self.exit_on_failure?
      true
    end

    no_commands do
      def configure_from_options
        Lopata.configure do |c|
          c.env = options[:env].to_sym
          c.keep = options[:keep]
          c.load_environment
          c.run_before_start_hooks
        end
      end

      def add_text_filter(text)
        Lopata.configuration.filters << -> (scenario) { scenario.title.include?(text) }
      end

      def add_rerun_filter
        to_rerun = Lopata::Client.new.to_rerun
        Lopata.configuration.filters << -> (scenario) { to_rerun.include?(scenario.title) }
      end

      def trap_interrupt
        trap('INT') { exit!(1) }
      end

      def list_scenarios
        Lopata.world.scenarios.each { |s| puts s.title }
      end

      def init_scenarios
        client = Lopata::Client.new
        client.init_scenarios(Lopata.world)
      end

      def run_scenarios
        world = Lopata.world
        world.notify_observers(:started, world)
        world.scenarios.each { |s| s.run }
        world.notify_observers(:finished, world)
      end
    end
  end
end

unless ARGV.first == 'new'
  eval File.binread('./Lopatafile') if File.exist?('./Lopatafile')
end

