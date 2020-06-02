module Lopata
  module Observers
    # @private
    # Based on RSpec::Core::BacktraceFormatter
    #
    # Provides ability to format backtrace and find source code by file and line number.
    class BacktraceFormatter
      # @private
      attr_accessor :exclusion_patterns, :inclusion_patterns

      def initialize
        patterns = %w[ /lib\d*/ruby/ bin/ exe/lopata /lib/bundler/ /exe/bundle /\.rvm/ ]
        patterns.map! { |s| Regexp.new(s.gsub("/", File::SEPARATOR)) }

        @exclusion_patterns = [Regexp.union(*patterns)]
        @inclusion_patterns = []

        inclusion_patterns << Regexp.new(Dir.getwd)
      end

      # Filter backtrace.
      #
      # @param backtrace [Array<String>] exception backtrace
      # @return [Array<String>] backtrace lines except ruby libraries, gems and executable files.
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


      # Extracts error message from excetion
      #
      # @param exception [Exception]
      # @param include_backtrace [Boolean] whether to add formatted backtrace to output
      # @return [String] error message from excetion, incuding source code line.
      def error_message(exception, include_backtrace: false)
        backtrace = format(exception.backtrace)
        source_line = extract_source_line(backtrace.first)
        msg = ''
        msg << "\n#{source_line}\n" if source_line
        msg << "#{exception.class.name}: " unless exception.class.name =~ /RSpec/
        msg << exception.message if exception.message
        msg << "\n#{backtrace.join("\n")}\n" if include_backtrace
        msg
      end

      def extract_source_line(backtrace_line)
        file_and_line_number = backtrace_line.match(/(.+?):(\d+)(|:\d+)/)
        return nil unless file_and_line_number
        file_path, line_number = file_and_line_number[1..2]
        return nil unless File.exist?(file_path)
        lines = File.read(file_path).split("\n")
        lines[line_number.to_i - 1]
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
