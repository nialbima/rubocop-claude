# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Detects commented-out code blocks.
      #
      # Commented-out code is technical debt. It clutters the codebase,
      # confuses readers, and version control already preserves history.
      # Delete it instead of commenting it out.
      #
      # @example
      #   # bad
      #   # def old_method
      #   #   do_something
      #   # end
      #
      #   # bad
      #   # user.update!(name: "test")
      #   # User.find(1).destroy
      #
      #   # good - explanatory comments are fine
      #   # This method handles user authentication
      #   def authenticate
      #   end
      #
      class NoCommentedCode < Base
        MSG = 'Delete commented-out code instead of leaving it. Version control preserves history.'

        # Patterns that strongly suggest commented-out Ruby code
        CODE_PATTERNS = [
          # Method definitions
          /\A\s*def\s+\w+/,
          # Class/module definitions
          /\A\s*(?:class|module)\s+[A-Z]/,
          # Control flow
          /\A\s*(?:if|unless|case|while|until|for|begin|rescue|ensure|end)\b/,
          # Method calls with receiver (foo.bar, foo.bar!, foo.bar?)
          /\A\s*\w+\.\w+[!(?)]*\s*(?:\(|do\b|$)/,
          # Bare method calls (do_something, process_data, etc.)
          /\A\s*[a-z_]\w*[!(?)]\s*$/,
          /\A\s*[a-z_]\w+\s*$/,
          # Assignments
          %r{\A\s*(?:@{1,2}|\$)?\w+\s*[+\-*/]?=\s*.+},
          # Return statements
          /\A\s*return\b/,
          # Raise statements
          /\A\s*raise\b/,
          # Require/require_relative
          /\A\s*require(?:_relative)?\s+['"]/,
          # Block syntax
          /\A\s*(?:do|\{)\s*(?:\|.*\|)?$/,
          # Array/hash literals being assigned
          /\A\s*\w+\s*=\s*[\[{]/,
          # Method chains
          /\A\s*\.\w+/,
          # Constants
          /\A\s*[A-Z][A-Z0-9_]*\s*=/,
          # Instance variable access that looks like code
          /\A\s*@\w+\.\w+/
        ].freeze

        # Patterns that suggest it's a regular comment, not code
        NON_CODE_PATTERNS = [
          # Documentation comments
          /\A\s*(?:TODO|FIXME|NOTE|HACK|XXX|OPTIMIZE|REVIEW)\b/i,
          # Looks like prose (multiple words without operators)
          /\A\s*[A-Z][a-z]+(?:\s+[a-z]+){3,}/,
          # Section headers
          /\A\s*[=-]{3,}/,
          # URLs
          %r{\A\s*https?://},
          # File paths as documentation
          /\A\s*(?:See|see|cf\.?|ref\.?)\s+/,
          # Rubocop directives
          /\A\s*rubocop:/,
          # Frozen string literal
          /\A\s*frozen_string_literal:/,
          # Encoding comments
          /\A\s*(?:encoding|coding):/,
          # Magic comments
          /\A\s*-\*-.*-\*-/,
          # YARD/RDoc tags (not @example - handled separately)
          /\A\s*@(?:param|return|raise|see|note|deprecated|option|yield|yieldparam|yieldreturn|api|abstract|overload)/
        ].freeze

        # YARD tags that start example blocks (code follows on subsequent indented lines)
        YARD_EXAMPLE_START = /\A#\s*@example/

        def on_new_investigation
          min_lines = cop_config.fetch('MinLines', 2)
          consecutive_code_comments = []
          in_yard_example = false

          processed_source.comments.each do |comment|
            # Skip inline comments (comments on same line as code)
            next if inline_comment?(comment)

            content = extract_content(comment)
            raw_text = comment.text

            # Track YARD @example blocks - code inside is documentation, not dead code
            if raw_text.match?(YARD_EXAMPLE_START)
              report_if_threshold_met(consecutive_code_comments, min_lines)
              consecutive_code_comments = []
              in_yard_example = true
              next
            end

            # Inside YARD example: indented lines are example code, skip them
            # Exit when we hit a non-indented line or another YARD tag
            if in_yard_example
              next if yard_example_content?(raw_text)

              in_yard_example = false

            end

            if looks_like_code?(content)
              consecutive_code_comments << comment
            else
              report_if_threshold_met(consecutive_code_comments, min_lines)
              consecutive_code_comments = []
            end
          end

          # Check remaining comments at end of file
          report_if_threshold_met(consecutive_code_comments, min_lines)
        end

        private

        def yard_example_content?(raw_text)
          # YARD example content is indented with spaces after the #
          # Example: "#   code_here" or "#     more_code"
          # Exit on: "# text" (no leading space) or "# @tag" (new YARD tag)
          return false if raw_text.match?(/\A#\s*@/)  # New YARD tag
          return false if raw_text.match?(/\A#[^ ]/)  # No space after #
          return false if raw_text.match?(/\A#\s?\S/) && !raw_text.match?(/\A#\s{2,}/) # Single space + content = prose

          # Indented content (2+ spaces after #) or empty comment line
          raw_text.match?(/\A#\s{2,}/) || raw_text.match?(/\A#\s*$/)
        end

        def inline_comment?(comment)
          line = processed_source.lines[comment.location.line - 1]
          # Check if there's non-whitespace content before the comment
          line_before_comment = line[0...comment.location.column]
          line_before_comment.match?(/\S/)
        end

        def extract_content(comment)
          # Remove the leading # and any leading whitespace
          comment.text.sub(/\A#\s?/, '')
        end

        def looks_like_code?(content)
          return false if content.strip.empty?
          return false if non_code_comment?(content)

          CODE_PATTERNS.any? { |pattern| content.match?(pattern) }
        end

        def non_code_comment?(content)
          NON_CODE_PATTERNS.any? { |pattern| content.match?(pattern) }
        end

        def report_if_threshold_met(comments, min_lines)
          return if comments.length < min_lines

          # Report on the first comment of the block
          first_comment = comments.first
          add_offense(first_comment)
        end
      end
    end
  end
end
