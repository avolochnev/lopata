require_relative 'backtrace_formatter'
require 'forwardable'

module Lopata
  module Observers
    # @private
    class ConsoleOutputObserver < BaseObserver
      extend Forwardable
      # @private
      attr_reader :output, :statuses
      # @private
      def_delegators :output, :puts, :flush

      def initialize
        @output = $stdout
      end

      def started(world)
        @statuses = {}
      end

      # @see Lopata::Observers::BaseObserver#finished
      def finished(world)
        total = statuses.values.inject(0, &:+)
        counts = statuses.map do |status, count|
          colored("%d %s", status) % [count, status]
        end
        details = counts.empty? ? "" : "(%s)" % counts.join(', ')
        puts "#{total} scenario%s %s" % [total == 1 ? '' : 's', details]
      end

      # @see Lopata::Observers::BaseObserver#scenario_finished
      def scenario_finished(scenario)
        message = "#{scenario.title} #{bold(scenario.status.to_s.upcase)}"
        puts colored(message, scenario.status)

        statuses[scenario.status] ||= 0
        statuses[scenario.status] += 1

        log_steps(scenario.steps) if scenario.failed?

        flush
      end

      # @private
      def log_steps(steps)
        steps.each do |step|
          next unless step.loggable?
          if step.group?
            status = step.status
            if %i{ passed skipped ignored }.include?(status)
              puts colored("  #{status_marker(step.status)} #{step.title}", status)
            else
              log_steps(step.steps)
            end
          else
            puts colored("  #{status_marker(step.status)} #{step.title}", step.status)
            puts indent(4, backtrace_formatter.error_message(step.exception, include_backtrace: true)) if step.failed?
          end
        end
      end

      private

      def colored(text, status)
        case status
        when :failed then red(text)
        when :passed then green(text)
        when :skipped, :ignored then cyan(text)
        when :pending then yellow(text)
        else text
        end
      end

      {
        red: 31,
        green: 32,
        cyan: 36,
        yellow: 33,
        bold: 1,
      }.each do |color, code|
        define_method(color) do |text|
          wrap(text, code)
        end
      end

      def wrap(text, code)
        "\e[#{code}m#{text}\e[0m"
      end

      def backtrace_formatter
        @backtrace_formatter ||= Lopata::Observers::BacktraceFormatter.new
      end

      def status_marker(status)
        case status
        when :failed then "[!]"
        when :skipped, :ignored then "[-]"
        when :pending then "[?]"
        else "[+]"
        end
      end

      # Adds indent to text
      # @param cols [Number] number of spaces to be added
      # @param text [String] text to add indent
      # @return [String] text with indent
      def indent(cols, text)
        text.split("\n").map { |line| " " * cols + line }.join("\n")
      end
    end
  end
end
