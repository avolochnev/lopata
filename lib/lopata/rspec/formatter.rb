require 'rspec/core/formatters/base_formatter'
require 'httparty'
require 'json'
require 'lopata/config'

module Lopata
  module RSpec
    class Formatter < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :start, :example_passed, :example_pending, :example_failed

      def start(notification)
        raise "Build number is not initailzed in Lopata::Config" unless Lopata::Config.build_number
        @client = Lopata::Client.new(Lopata::Config.build_number)
        @client.start(notification.count)
      end

      def example_passed(notification)
        @client.add_attempt(notification.example, Lopata::PASSED)
      end

      def example_failed(notification)
        example = notification.example
        @client.add_attempt(example, Lopata::FAILED, error_message_for(example), backtrace_for(notification))
      end

      def example_pending(notification)
        example = notification.example
        @client.add_attempt(example, Lopata::PENDING, example.execution_result.pending_message)
      end

      private

      def error_message_for(example)
        exception = example.execution_result.exception
        msg = ''
        msg << "#{exception.class.name}: " unless exception.class.name =~ /RSpec/
        msg << "#{exception.message.to_s}" if exception.message
        msg.blank? ? 'Empty message' : msg
      end

      def backtrace_for(notification)
        example = notification.example
        exception = example.execution_result.exception
        msg = notification.message_lines.map(&:strip).join("\n")
        msg << "\n"
        if shared_group = find_shared_group(example)
          msg << "# Shared Example Group: \"#{shared_group.metadata[:shared_group_name]}\" called from "
          msg << "#{backtrace_line(shared_group.metadata[:example_group][:location])}\n"
        end
        msg
      end

      def find_shared_group(example)
        group_and_parent_groups(example).find {|group| group.metadata[:shared_group_name]}
      end

      def group_and_parent_groups(example)
        example.example_group.parent_groups + [example.example_group]
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
      @launch_id = JSON.parse(post("/builds/#{build_number}/launches.json", body: {total: count}).body)['id']
    end

    def add_attempt(example, status, msg = nil, backtrace = nil)
      test = test_id(example)
      request = { status: status}
      request[:message] = msg if msg
      request[:backtrace] = backtrace if backtrace
      post("/tests/#{test}/attempts.json", body: request)
      inc_finished
    end

    def test_id(example)
      request = {
        find_or_create: {
          title: example.full_description,
          scenario: example.metadata[:example_group][:full_description],
          build_number: build_number
        }
      }
      response = post("/tests.json", body: request)
      JSON.parse(response.body)["id"]
    end

    def to_rerun
      get_json("/builds/#{build_number}/suspects.json")
    end

    def to_full_rescan
      to_rerun + get_json("/builds/#{build_number}/failures.json")
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
      response = patch("/builds/#{build_number}/launches/#{@launch_id}",
        body: { finished: @finished }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
      if response.code == 404
        puts 'Launch has been cancelled. Exit.'
        exit!
      end
    end
  end
end

