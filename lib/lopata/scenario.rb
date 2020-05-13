require 'rspec/expectations'

class Lopata::Scenario
  include RSpec::Matchers

  attr_reader :title, :metadata, :steps, :status

  def initialize(title, options_title, metadata = {})
    @title = [title, options_title].compact.reject(&:empty?).join(' ')
    @metadata = metadata
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

  def world
    @world ||= Lopata::Config.world
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