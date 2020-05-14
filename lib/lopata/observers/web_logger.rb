require 'httparty'
require 'json'
require_relative 'backtrace_formatter'

module Lopata
  module Observers
    class WebLogger < BaseObserver
      def started(world)
        raise "Build number is not initailzed in Lopata::Config" unless Lopata::Config.build_number
        @client = Lopata::Client.new(Lopata::Config.build_number)
        @client.start(world.scenarios.count)
      end

      def scenario_finished(scenario)
        if scenario.failed?
          backtrace = backtrace_for(scenario)
          @client.add_attempt(scenario, Lopata::FAILED, error_message_for(scenario), backtrace)
        else
          @client.add_attempt(scenario, Lopata::PASSED)
        end
      end

      # def example_pending(notification)
      #   example = notification.example
      #   @client.add_attempt(example, Lopata::PENDING, example.execution_result.pending_message)
      # end

      private

      def error_message_for(scenario)
        exception = scenario.steps.map(&:exception).compact.last
        if exception
          backtrace_formatter.error_message(exception)
        else
          'Empty error message'
        end
      end

      def backtrace_for(scenario)
        exception = scenario.steps.map(&:exception).compact.last
        msg = ''
        if exception
          msg = backtrace_formatter.format(exception.backtrace).join("\n")
          msg << "\n"
        end
        msg
      end

      def backtrace_formatter
        @backtrace_formatter ||= Lopata::Observers::BacktraceFormatter.new
      end
    end
  end

  PASSED = 0
  FAILED = 1
  PENDING = 2

  class Client
    include HTTParty
    base_uri Lopata::Config.lopata_host

    attr_accessor :build_number

    def initialize(build_number)
      @build_number = build_number
    end

    def start(count)
      @launch_id = JSON.parse(post("/projects/#{project_code}/builds/#{build_number}/launches.json", body: {total: count}).body)['id']
    end

    def add_attempt(scenario, status, msg = nil, backtrace = nil)
      test = test_id(scenario)
      request = { status: status}
      request[:message] = msg if msg
      request[:backtrace] = backtrace if backtrace
      post("/tests/#{test}/attempts.json", body: request)
      inc_finished
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

    def get_json(url)
      JSON.parse(self.class.get(url).body)
    end

    def post(*args)
      self.class.post(*args)
    end

    def patch(*args)
      self.class.patch(*args)
    end

    def inc_finished
      @finished ||= 0
      @finished += 1
      response = patch("/launches/#{@launch_id}",
        body: { finished: @finished }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
      if response.code == 404
        puts 'Launch has been cancelled. Exit.'
        exit!
      end
    end

    def project_code
      Lopata::Config.lopata_code
    end
  end
end