# frozen_string_literal: true

require 'set'

module RuboCop
  module Cop
    module Claude
      # Detects patterns that preserve dead code for backwards compatibility.
      #
      # AI assistants often add "helpful" compatibility shims instead of
      # cleanly removing code. This creates confusion and maintenance burden.
      # If code is unused, delete it completely.
      #
      # == Detection Philosophy
      #
      # This cop catches *self-documented* compatibility hacks - patterns where
      # the code includes comments like "for backwards compatibility" or markers
      # like "# removed:". It won't catch silent compat hacks without comments.
      #
      # This is intentional. The goal is teaching, not comprehensive detection.
      # When the cop fires, it's a teaching moment - the AI reads the guidance
      # and learns the principle "don't preserve dead code." Over time, this
      # shapes better habits even for cases we can't detect.
      #
      # @example Dead code marker comments (always flagged)
      #   # bad
      #   # removed: def old_method; end
      #   # deprecated: use new_method instead
      #   # legacy: keeping for backwards compat
      #   # backwards compatibility: aliased from OldClass
      #
      #   # good - just delete the comment entirely
      #
      # @example Constant re-exports with compat comments (always flagged)
      #   # bad
      #   OldName = NewName  # for backwards compatibility
      #
      #   # bad
      #   # deprecated alias
      #   LegacyClass = ModernClass
      #
      #   # good - delete the alias, update callers
      #
      # @example CheckUnderscoreAssignments: true (optional, off by default)
      #   # bad - underscore prefix to silence unused variable warning
      #   _old_method = :deprecated
      #   _unused = previous_value
      #
      #   # good - delete the line entirely if not needed
      #
      #   # ok - single underscore in blocks is idiomatic Ruby
      #   hash.each { |_, v| puts v }
      #
      class NoBackwardsCompatHacks < Base
        MSG_UNDERSCORE = "Delete dead code. Don't use underscore prefix to preserve unused values."
        MSG_REEXPORT = "Delete dead code. Don't re-export removed constants for backwards compatibility."
        MSG_COMMENT = "Delete dead code. Don't leave removal markers in comments."

        # Comments that indicate removed/deprecated code being preserved
        DEAD_CODE_COMMENT_PATTERN = /\A#\s*(?:removed|deprecated|legacy|backwards?\s*compat(?:ibility)?|for\s+compat(?:ibility)?|compat(?:ibility)?\s+shim):/i

        # Patterns for detecting backwards-compatibility comments near constant assignments
        COMPAT_KEYWORD_PATTERN = /\b(?:backwards?\s*)?compat(?:ibility)?\b/i
        LEGACY_REFERENCE_PATTERN = /\bfor\s+(?:legacy|old|previous)\b/i
        DEPRECATED_PATTERN = /\bdeprecated\b/i
        ALIAS_PATTERN = /\balias\s+for\b/i

        # Assignment to underscore-prefixed variables (not just _ which is idiomatic for unused block args)
        UNDERSCORE_ASSIGNMENT_MSG = 'Assignment to underscore-prefixed variable'

        def on_new_investigation
          build_compat_comment_index
          check_dead_code_comments
        end

        # Detect _unused = value patterns (optional, off by default)
        def on_lvasgn(node)
          return unless check_underscore_assignments?

          var_name = node.children[0].to_s
          return unless var_name.start_with?('_') && var_name.length > 1

          # Allow in block parameters context (common Ruby idiom)
          return if in_block_arguments?(node)

          add_offense(node, message: MSG_UNDERSCORE)
        end

        # Detect Constant = OtherConstant patterns with backwards compat comments
        def on_casgn(node)
          # Check for re-export patterns: OldName = NewName
          _, _, value = *node
          return unless value.const_type?

          # Look for backwards compatibility indicators in nearby comments
          return unless has_compat_comment_nearby?(node)

          add_offense(node, message: MSG_REEXPORT)
        end

        private

        def build_compat_comment_index
          @compat_comment_lines = Set.new
          processed_source.comments.each do |comment|
            @compat_comment_lines << comment.location.line if compat_comment?(comment.text)
          end
        end

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
          @compat_comment_lines.include?(line) || @compat_comment_lines.include?(line - 1)
        end

        def compat_comment?(text)
          COMPAT_KEYWORD_PATTERN.match?(text) ||
            LEGACY_REFERENCE_PATTERN.match?(text) ||
            DEPRECATED_PATTERN.match?(text) ||
            ALIAS_PATTERN.match?(text)
        end

        def check_underscore_assignments?
          @check_underscore_assignments ||= cop_config.fetch('CheckUnderscoreAssignments', false)
        end
      end
    end
  end
end
