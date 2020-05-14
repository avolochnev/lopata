module Lopata
  module Observers
    # Based on RSpec::Core::BacktraceFormatter
    class BacktraceFormatter
      attr_accessor :exclusion_patterns, :inclusion_patterns

      def initialize
        patterns = %w[ /lib\d*/ruby/ bin/ exe/lopata /lib/bundler/ /exe/bundle: ]
        patterns.map! { |s| Regexp.new(s.gsub("/", File::SEPARATOR)) }

        @exclusion_patterns = [Regexp.union(*patterns)]
        @inclusion_patterns = []

        inclusion_patterns << Regexp.new(Dir.getwd)
      end

      def format(backtrace)
        return [] unless backtrace
        return backtrace if backtrace.empty?

        backtrace.map { |l| backtrace_line(l) }.compact.
          tap do |filtered|
            if filtered.empty?
              filtered.concat backtrace
              filtered << ""
              filtered << "  Showing full backtrace because every line was filtered out."
            end
          end
      end

      def backtrace_line(line)
        relative_path(line) unless exclude?(line)
      end

      def exclude?(line)
        matches?(exclusion_patterns, line) && !matches?(inclusion_patterns, line)
      end

      private

      def matches?(patterns, line)
        patterns.any? { |p| line =~ p }
      end

      # Matches strings either at the beginning of the input or prefixed with a
      # whitespace, containing the current path, either postfixed with the
      # separator, or at the end of the string. Match groups are the character
      # before and the character after the string if any.
      #
      # http://rubular.com/r/fT0gmX6VJX
      # http://rubular.com/r/duOrD4i3wb
      # http://rubular.com/r/sbAMHFrOx1
      def relative_path_regex
        @relative_path_regex ||= /(\A|\s)#{File.expand_path('.')}(#{File::SEPARATOR}|\s|\Z)/
      end

      # @param line [String] current code line
      # @return [String] relative path to line
      def relative_path(line)
        line = line.sub(relative_path_regex, "\\1.\\2".freeze)
        line = line.sub(/\A([^:]+:\d+)$/, '\\1'.freeze)
        return nil if line == '-e:1'.freeze
        line
      rescue SecurityError
        nil
      end
    end
  end
end