# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Enforces attribution on TODO/NOTE/FIXME/HACK comments.
      #
      # Anonymous TODO comments lose context over time. Who wrote it?
      # When? What was the context? Attribution helps track ownership.
      #
      # @example
      #   # bad
      #   # TODO: Fix this later
      #   # FIXME: Handle edge case
      #   # NOTE: This is important
      #
      #   # good
      #   # TODO [@nabm]: Fix this later
      #   # FIXME [Nick - @nabm]: Handle edge case
      #   # NOTE [@claude]: This is important
      #
      class TaggedComments < Base
        MSG = "Comments need attribution. Use format: # %<keyword>s [@handle]: description"

        # Matches valid attribution: [@handle] or [Name - @handle]
        ATTRIBUTION_PATTERN = /\[(?:[\w\s]+-\s*)?@[\w-]+\]/

        def on_new_investigation
          keywords = cop_config.fetch("Keywords", %w[TODO FIXME NOTE HACK OPTIMIZE REVIEW])
          # Build regex pattern: matches keyword followed by optional colon, then content
          # Does NOT match if there's a [@handle] pattern immediately
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
