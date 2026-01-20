# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Enforces attribution on TODO/NOTE/FIXME/HACK comments.
      #
      # Anonymous TODO comments lose context over time. Who wrote it?
      # When? What was the context? Attribution helps track ownership
      # and distinguishes human-written comments from AI-generated ones.
      #
      # @example Default (attribution required)
      #   # bad
      #   # TODO: Fix this later
      #   # FIXME: Handle edge case
      #
      #   # good - handle format (after colon, compatible with Style/CommentAnnotation)
      #   # TODO: [@username] Fix this later
      #   # FIXME: [Alice - @alice] Handle edge case
      #
      # @example Case insensitive (keywords matched regardless of case)
      #   # bad
      #   # todo: fix this
      #   # Todo: Fix this
      #
      # @example AI assistant attribution
      #   # good - AI-generated comments use @claude
      #   # TODO: [@claude] Refactor to reduce complexity
      #   # NOTE: [@claude] This pattern matches the factory in user.rb
      #
      # @example Keywords: ['TODO', 'FIXME'] (custom keyword list)
      #   # With custom keywords, only those are checked
      #   # bad - TODO is in the list
      #   # TODO: Fix this
      #
      #   # good - NOTE not in the custom list, so not checked
      #   # NOTE: No attribution needed
      #
      # @example Valid attribution formats
      #   [@handle]              # Just handle
      #   [Name - @handle]       # Name and handle
      #   [First Last - @handle] # Full name and handle
      #
      class TaggedComments < Base
        MSG = 'Comments need attribution. Use format: # %<keyword>s: [@handle] description'

        ATTRIBUTION_PATTERN = /\[(?:[\w\s]+-\s*)?@[\w-]+\]/ # Matches valid attribution: [@handle] or [Name - @handle]

        def on_new_investigation
          keywords = cop_config.fetch('Keywords', %w[TODO FIXME NOTE HACK OPTIMIZE REVIEW])
          pattern_str = "\\A#\\s*(#{keywords.join("|")}):?\\s+(?!\\[[@\\w])"
          @keyword_regex = Regexp.new(pattern_str, Regexp::IGNORECASE)

          processed_source.comments.each do |comment|
            check_comment(comment)
          end
        end

        private

        def check_comment(comment)
          text = comment.text
          match = text.match(@keyword_regex)
          return unless match

          keyword = match[1].upcase

          # Check if attribution exists somewhere in the comment
          return if text.match?(ATTRIBUTION_PATTERN)

          add_offense(comment, message: format(MSG, keyword: keyword))
        end
      end
    end
  end
end
