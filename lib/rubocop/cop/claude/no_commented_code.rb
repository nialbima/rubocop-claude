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
      # @example Default (flags consecutive commented code)
      #   # bad
      #   # def old_method
      #   #   do_something
      #   # end
      #
      # @example AllowKeep: true (default) - explicit exceptions with attribution
      #   # good - KEEP comment with attribution
      #   # KEEP [@username]: Rollback path, remove after 2025-06
      #   # def legacy_method
      #   #   old_implementation
      #   # end
      #
      # @safety
      #   Autocorrection deletes commented code. Review changes to ensure
      #   no important context is lost. Version control preserves history.
      #
      class NoCommentedCode < Base
        extend AutoCorrector

        MSG = 'Delete commented-out code instead of leaving it. Version control preserves history.'

        # Patterns that strongly suggest commented-out Ruby code
        CODE_PATTERNS = [
          /\A\s*def\s+\w+/,                                     # Method definitions
          /\A\s*(?:class|module)\s+[A-Z]/,                      # Class/module definitions
          /\A\s*(?:if|unless|case|while|until|begin|end)\b/,   # Control flow
          /\A\s*\w+\.\w+[!(?)]*\s*(?:\(|do\b|$)/,              # Method calls with receiver
          /\A\s*[a-z_]\w*[!(?)]\s*$/,                           # Bare method calls with ! or ?
          /\A\s*[a-z_]\w+\s*$/,                                 # Bare identifiers
          %r{\A\s*(?:@{1,2}|\$)?\w+\s*[+\-*/]?=\s*.+},         # Assignments
          /\A\s*(?:return|raise)\b/,                            # Return/raise statements
          /\A\s*require(?:_relative)?\s+['"]/,                  # Require statements
          /\A\s*\.\w+/,                                         # Method chains
          /\A\s*[A-Z][A-Z0-9_]*\s*=/                            # Constants
        ].freeze

        # Patterns that suggest prose, not code
        NON_CODE_PATTERNS = [
          /\A\s*(?:TODO|FIXME|NOTE|HACK|OPTIMIZE|REVIEW)\b/i,  # Annotations
          /\A\s*[A-Z][a-z]+(?:\s+[a-z]+){3,}/,                 # Prose sentences
          %r{\A\s*https?://},                                   # URLs
          /\A\s*rubocop:/,                                      # Rubocop directives
          /\A\s*@(?:param|return|raise|see|note|deprecated)/   # YARD tags
        ].freeze

        YARD_EXAMPLE_START = /\A#\s*@example/
        KEEP_PATTERN = /\A#\s*KEEP\s+\[(?:[\w\s]+-\s*)?@[\w-]+\]:/i

        def on_new_investigation
          @min_lines = cop_config.fetch('MinLines', 1)
          @state = initial_state

          processed_source.comments.each { |comment| process_comment(comment) }
          report_pending_comments
        end

        private

        def initial_state
          {consecutive: [], in_yard_example: false, preceded_by_keep: false}
        end

        def process_comment(comment)
          return if inline_comment?(comment)

          raw_text = comment.text
          return handle_yard_example_start if raw_text.match?(YARD_EXAMPLE_START)
          return handle_keep_comment if allow_keep? && raw_text.match?(KEEP_PATTERN)
          return if skip_yard_example_content?(raw_text)

          accumulate_or_report(comment)
        end

        def handle_yard_example_start
          report_and_reset
          @state[:in_yard_example] = true
        end

        def handle_keep_comment
          report_and_reset
          @state[:preceded_by_keep] = true
        end

        def report_and_reset
          report_pending_comments
          @state[:consecutive] = []
          @state[:preceded_by_keep] = false
        end

        def skip_yard_example_content?(raw_text)
          return false unless @state[:in_yard_example]
          return true if yard_example_content?(raw_text)

          @state[:in_yard_example] = false
          false
        end

        def accumulate_or_report(comment)
          content = extract_content(comment)

          if looks_like_code?(content)
            @state[:consecutive] << comment
          else
            report_pending_comments
            @state[:preceded_by_keep] = false
          end
        end

        def report_pending_comments
          comments = @state[:consecutive]
          return if comments.length < @min_lines

          # KEEP protection - clear without reporting
          if @state[:preceded_by_keep]
            @state[:consecutive] = []
            return
          end

          add_offense(comments.first) { |corrector| remove_comment_block(corrector, comments) }
          @state[:consecutive] = []
        end

        def yard_example_content?(raw_text)
          return false if raw_text.match?(/\A#\s*@/)
          return false if raw_text.match?(/\A#[^ ]/)
          return false if raw_text.match?(/\A#\s?\S/) && !raw_text.match?(/\A#\s{2,}/)

          raw_text.match?(/\A#\s{2,}/) || raw_text.match?(/\A#\s*$/)
        end

        def inline_comment?(comment)
          line = processed_source.lines[comment.location.line - 1]
          line[0...comment.location.column].match?(/\S/)
        end

        def extract_content(comment)
          comment.text.sub(/\A#\s?/, '')
        end

        def looks_like_code?(content)
          return false if content.strip.empty?
          return false if NON_CODE_PATTERNS.any? { |p| content.match?(p) }

          CODE_PATTERNS.any? { |p| content.match?(p) }
        end

        def remove_comment_block(corrector, comments)
          source = comments.first.location.expression.source_buffer
          begin_pos = source.line_range(comments.first.location.line).begin_pos
          end_pos = calculate_end_pos(source, comments.last.location.line)

          corrector.remove(Parser::Source::Range.new(source, begin_pos, end_pos))
        end

        def calculate_end_pos(source, last_line)
          next_line = last_line + 1
          if next_line <= source.last_line
            source.line_range(next_line).begin_pos
          else
            source.line_range(last_line).end_pos
          end
        end

        def allow_keep?
          @allow_keep ||= cop_config.fetch('AllowKeep', true)
        end
      end
    end
  end
end
