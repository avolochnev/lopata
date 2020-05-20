require_relative 'backtrace_formatter'

module Lopata
  module Observers
    class ConsoleOutputObserver < BaseObserver
      def finished(world)
        total = world.scenarios.length
        statuses = world.scenarios.map(&:execution).map(&:status)
        counts = statuses.uniq.map do |status|
          colored("%d %s", status) % [statuses.count { |s| s == status }, status]
        end
        details = counts.empty? ? "" : "(%s)" % counts.join(', ')
        puts "#{total} scenario%s %s" % [total == 1 ? '' : 's', details]
      end

      def scenario_finished(scenario)
        message = "#{scenario.title} #{bold(scenario.status.to_s.upcase)}"
        puts colored(message, scenario.status)
        return unless scenario.failed?

        scenario.steps_in_running_order.each do |step|
          puts colored("  #{status_marker(step.status)} #{step.title}", step.status)
          puts indent(4, backtrace_formatter.error_message(step.exception, include_backtrace: true)) if step.failed?
        end
      end

      private

      def colored(text, status)
        case status
        when :failed then red(text)
        when :passed then green(text)
        when :skipped then cyan(text)
        else text
        end
      end

      def red(text)
        wrap(text, 31)
      end

      def green(text)
        wrap(text, 32)
      end

      def cyan(text)
        wrap(text, 36)
      end

      def bold(text)
        wrap(text, 1)
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
        when :skipped then "[-]"
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
