# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Detects patterns that preserve dead code for backwards compatibility.
      #
      # AI assistants often add "helpful" compatibility shims instead of
      # cleanly removing code. This creates confusion and maintenance burden.
      # If code is unused, delete it completely.
      #
      # @example
      #   # bad - underscore prefix to silence unused variable warning
      #   _old_method = :deprecated
      #   _unused = previous_value
      #
      #   # bad - re-exporting for "compatibility"
      #   OldName = NewName  # for backwards compatibility
      #
      #   # bad - legacy comments indicating dead code
      #   # removed: def old_method; end
      #   # deprecated: use new_method instead
      #   # legacy: keeping for backwards compat
      #
      #   # good - just delete the old code
      #   def new_method
      #     # implementation
      #   end
      #
      class NoBackwardsCompatHacks < Base
        MSG_UNDERSCORE = "Delete dead code. Don't use underscore prefix to preserve unused values."
        MSG_REEXPORT = "Delete dead code. Don't re-export removed constants for backwards compatibility."
        MSG_COMMENT = "Delete dead code. Don't leave removal markers in comments."

        # Comments that indicate removed/deprecated code being preserved
        DEAD_CODE_COMMENT_PATTERN = /\A#\s*(?:removed|deprecated|legacy|backwards?\s*compat(?:ibility)?|for\s+compat(?:ibility)?|compat(?:ibility)?\s+shim):/i

        # Assignment to underscore-prefixed variables (not just _ which is idiomatic for unused block args)
        UNDERSCORE_ASSIGNMENT_MSG = "Assignment to underscore-prefixed variable"

        def on_new_investigation
          check_dead_code_comments
        end

        # Detect _unused = value patterns
        def on_lvasgn(node)
          var_name = node.children[0].to_s
          return unless var_name.start_with?("_") && var_name.length > 1

          # Allow in block parameters context (common Ruby idiom)
          return if in_block_arguments?(node)

          # Check if it's a simple assignment that looks like dead code preservation
          # e.g., _old = something, _unused = previous_value
          add_offense(node, message: MSG_UNDERSCORE)
        end

        # Detect Constant = OtherConstant patterns with backwards compat comments
        def on_casgn(node)
          # Check for re-export patterns: OldName = NewName
          _, const_name, value = *node
          return unless value&.const_type?

          # Look for backwards compatibility indicators in nearby comments
          return unless has_compat_comment_nearby?(node)

          add_offense(node, message: MSG_REEXPORT)
        end

        private

        def check_dead_code_comments
          processed_source.comments.each do |comment|
            next unless comment.text.match?(DEAD_CODE_COMMENT_PATTERN)

            add_offense(comment, message: MSG_COMMENT)
          end
        end

        def in_block_arguments?(node)
          node.each_ancestor(:block, :numblock).any?
        end

        def has_compat_comment_nearby?(node)
          line = node.location.line

          # Check comments on same line or line before
          processed_source.comments.any? do |comment|
            comment_line = comment.location.line
            (comment_line == line || comment_line == line - 1) &&
              compat_comment?(comment.text)
          end
        end

        def compat_comment?(text)
          text.match?(/\b(?:backwards?\s*)?compat(?:ibility)?\b/i) ||
            text.match?(/\bfor\s+(?:legacy|old|previous)\b/i) ||
            text.match?(/\bdeprecated\b/i) ||
            text.match?(/\balias\s+for\b/i)
        end
      end
    end
  end
end
