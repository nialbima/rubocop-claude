# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Detects hardcoded line numbers in comments and strings.
      #
      # Hardcoded line numbers become stale when code shifts. References
      # like "see line 42" or "foo.rb:123" break silently as the codebase
      # evolves. Use method names, class names, or other stable references.
      #
      # @example CheckComments: true (default)
      #   # bad
      #   # see line 42 for details
      #   # Error defined at foo.rb:123
      #   # Check L42 for the fix
      #   # at line 15, we handle errors
      #
      #   # good
      #   # see #validate_input for details
      #   # Error defined in FooError class
      #   # Check the validate_input method for the fix
      #
      # @example CheckStrings: true (default)
      #   # bad
      #   raise "Error at line 42"
      #   expect(error.message).to include("foo.rb:55")
      #
      #   # good
      #   raise "Error in validate_input"
      #   expect(error.message).to include("validate_input")
      #
      # @example MinLineNumber: 1 (default)
      #   # Only flags line numbers >= MinLineNumber
      #   # With MinLineNumber: 10, "line 5" would not be flagged
      #
      class NoHardcodedLineNumbers < Base
        MSG = 'Avoid hardcoded line number `%<line>s`. ' \
              'Line numbers shift when code changes.'

        # Patterns that look like line number references
        # Order matters - more specific patterns first
        LINE_PATTERNS = [
          /\bL(\d+)\b/,                       # "L42" (GitHub style)
          /\.(?:rb|erb|rake|ru):(\d+)\b/,     # "foo.rb:42", "app.erb:10"
          /\blines?\s+(\d+)/i                 # "line 42" or "lines 42"
        ].freeze

        # Patterns that look like line refs but aren't
        IGNORE_PATTERNS = [
          /ruby\s+\d+\.\d+/i,                 # "Ruby 3.1"
          /version\s+\d+/i,                   # "version 2"
          /port\s+\d+/i,                      # "port 8080"
          /\bv\d+\.\d+/i,                     # "v1.2.3"
          /\d+\.\d+\.\d+/,                    # "1.2.3" semver
          /pid[:\s]+\d+/i,                    # "pid: 1234"
          /id[:\s]+\d+/i,                     # "id: 42"
          /\d+\s*(?:ms|seconds?|minutes?)/i,  # "42ms", "5 seconds"
          /\d+\s*(?:bytes?|kb|mb|gb)/i,       # "100 bytes", "5mb"
          /\d+%/,                             # "50%"
          /\$\d+/,                            # "$42"
          /#\d+/,                             # "#42" (issue reference)
          %r{://[^/]*:\d+}                    # URLs with ports "http://localhost:8080"
        ].freeze

        def on_new_investigation
          return unless check_comments?

          processed_source.comments.each do |comment|
            check_for_line_numbers(comment.text, comment)
          end
        end

        def on_str(node)
          return unless check_strings?
          return if inside_heredoc?(node)

          check_for_line_numbers(node.value, node)
        end

        def on_dstr(node)
          return unless check_strings?
          return if inside_heredoc?(node)

          node.each_child_node(:str) do |str_node|
            check_for_line_numbers(str_node.value, str_node)
          end
        end

        private

        def check_for_line_numbers(text, node)
          return if text.nil? || text.empty?
          return if matches_ignore_pattern?(text)

          match = find_first_line_number(text)
          return unless match

          add_offense(node, message: format(MSG, line: match))
        end

        def find_first_line_number(text)
          min = min_line_number
          LINE_PATTERNS.each do |pattern|
            text.scan(pattern) do |capture|
              line_num = Array(capture).first
              next unless line_num && line_num.to_i >= min

              return Regexp.last_match[0]
            end
          end
          nil
        end

        def matches_ignore_pattern?(text)
          IGNORE_PATTERNS.any? { |pattern| text.match?(pattern) }
        end

        def inside_heredoc?(node)
          return true if node.respond_to?(:heredoc?) && node.heredoc?

          node.each_ancestor do |ancestor|
            return true if ancestor.respond_to?(:heredoc?) && ancestor.heredoc?
          end
          false
        end

        def check_comments?
          @check_comments ||= cop_config.fetch('CheckComments', true)
        end

        def check_strings?
          @check_strings ||= cop_config.fetch('CheckStrings', true)
        end

        def min_line_number
          @min_line_number ||= cop_config.fetch('MinLineNumber', 1)
        end
      end
    end
  end
end
