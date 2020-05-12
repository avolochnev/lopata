require 'rspec/expectations'

class Lopata::Scenario
  include RSpec::Matchers

  attr_reader :title, :metadata, :steps, :status

  def initialize(*args)
    @title = args.first
    @metadata = args.last.is_a?(Hash) ? args.last : {}
    @steps = []
    @status = :not_runned
  end

  def run
    @status = :running
    world.notify_observers(:scenario_started, self)
    teardown_steps = []
    @steps.reject(&:teardown?).each { |step| step.run(self) }
    @steps.select(&:teardown?).each { |step| step.run(self) }
    @status = @steps.all?(&:passed?) ? :passed : :failed
    world.notify_observers(:scenario_finished, self)
  end

  def match_metadata?(metadata_key)
    case metadata_key
    when Hash
      metadata_key.keys.all? { |k| metadata[k] == metadata_key[k] }
    when Array
      metadata_key.map { |key| metadata[key] }.none?(&:nil?)
    else
      metadata[metadata_key]
    end
  end

  def run_step(method_name, *args, &block)
    instance_exec(&block)
  end

  def world
    @world ||= Lopata::Config.world
  end

  def convert_args(*args)
    args.map do |arg|
      case arg
        # trait symbols as link to metadata.
        when Symbol then metadata[arg]
      else
        arg
      end
    end.flatten
  end

  def separate_args(args)
    args.map { |a| a.is_a?(String) && a =~ /,/ ? a.split(',').map(&:strip) : a }.flatten
  end

  def failed?
    status == :failed
  end

  private

    def method_missing(method, *args, &block)
      if metadata.keys.include?(method)
        metadata[method]
      else
        super
      end
    end

    def respond_to_missing?(method, *)
      metadata.keys.include?(method) or super
    end
end