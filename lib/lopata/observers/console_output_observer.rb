require_relative 'backtrace_formatter'

module Lopata
  module Observers
    class ConsoleOutputObserver < BaseObserver
      def finished(world)
        total = world.scenarios.length
        statuses = world.scenarios.map(&:status)
        counts = statuses.uniq.map do |status|
          colored("%d %s", status) % [statuses.count { |s| s == status }, status]
        end
        details = counts.empty? ? "" : "(%s)" % counts.join(', ')
        puts "#{total} scenario%s %s" % [total == 1 ? '' : 's', details]
      end

      def step_finished(step)
        @failed_steps << step if step.failed?
      end

      def scenario_started(scenario)
        @failed_steps = []
      end

      def scenario_finished(scenario)
        message = "#{scenario.title} #{bold(scenario.status.to_s.upcase)}"
        puts colored(message, scenario.status)

        @failed_steps.each do |step|
          puts backtrace_formatter.error_message(step.exception, include_backtrace: true)
        end
      end

      private

      def colored(text, status)
        case status
        when :failed then red(text)
        when :passed then green(text)
        else text
        end
      end

      def red(text)
        wrap(text, 31)
      end

      def green(text)
        wrap(text, 32)
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
    end
  end
end
