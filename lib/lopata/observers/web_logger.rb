require 'httparty'
require 'json'
require_relative 'backtrace_formatter'

module Lopata
  module Observers
    # @private
    class WebLogger < BaseObserver
      def started(world)
        @client = Lopata::Client.new
        @client.start(world.scenarios.count)
        @finished = 0
      end

      def scenario_finished(scenario)
        @finished += 1
        @client.add_attempt(scenario, @finished)
      end
    end
  end

  # @private
  PASSED = 0
  # @private
  FAILED = 1
  # @private
  PENDING = 2
  # @private
  SKIPPED = 5

  # @private
  class Client
    include HTTParty

    attr_reader :url, :project_code, :build_number

    def initialize
      params = Lopata.configuration.web_logging_params
      raise "Web logging is not initailzed" unless params
      @url = HTTParty.normalize_base_uri(params[:url])
      @project_code = params[:project_code]
      @build_number = params[:build_number]
    end

    def start(count)
      @launch_id = JSON.parse(post("/projects/#{project_code}/builds/#{build_number}/launches.json", body: {total: count}).body)['id']
    end

    def add_attempt(scenario, finished)
      status = scenario.failed? ? Lopata::FAILED : Lopata::PASSED
      steps = build_hashes(scenario.steps)
      request = { status: status, steps: steps, launch: { id: @launch_id, finished: finished } }
      test = test_id(scenario)
      post("/tests/#{test}/attempts.json", body: request)
    rescue SocketError => e
      # Ignore network problems. Continue with next scenario when cannot log results.
      puts e.message
      puts e.backtrace
    end

    def build_hashes(steps)
      hashes = []
      steps.each do |step|
        next unless step.loggable?
        if step.group?
          if %i{ passed skipped ignored }.include?(step.status)
            hashes << group_hash(step)
          else
            hashes += build_hashes(step.steps)
          end
        else
          hashes << step_hash(step)
        end
      end
      hashes
    end

    def step_hash(step)
      hash = { status: step.status, title: step.title }
      if step.failed?
        hash[:message] = error_message_for(step)
        hash[:backtrace] = backtrace_for(step)
      end
      hash
    end

    def group_hash(group)
      { status: group.status, title: group.title }
    end

    def test_id(scenario)
      request = {
        test: {
          project_code: project_code,
          title: scenario.title,
          scenario: scenario.title,
          build_number: build_number
        }
      }
      response = post("/tests.json", body: request)
      JSON.parse(response.body)["id"]
    end

    def to_rerun
      get_json("/projects/#{project_code}/builds/#{build_number}/suspects.json")
    end

    def to_full_rescan
      to_rerun + get_json("/projects/#{project_code}/builds/#{build_number}/failures.json")
    end

    private

    def get_json(path)
      JSON.parse(self.class.get(path, base_uri: url).body)
    end

    def post(*args)
      self.class.post(*with_base_uri(args))
    end

    def patch(*args)
      self.class.patch(*with_base_uri(args))
    end

    def with_base_uri(args = [])
      if args.last.is_a? Hash
        args.last[:base_uri] = url
      else
        args << { base_uri: url }
      end
      args
    end

    def error_message_for(step)
      if step.exception
        backtrace_formatter.error_message(step.exception)
      else
        'Empty error message'
      end
    end

    def backtrace_for(step)
      msg = ''
      if step.exception
        msg = backtrace_formatter.format(step.exception.backtrace).join("\n")
        msg << "\n"
      end
      msg
    end

    def backtrace_formatter
      @backtrace_formatter ||= Lopata::Observers::BacktraceFormatter.new
    end
  end
end