# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Detects emoji characters in strings, comments, and symbols.
      #
      # AI assistants sometimes add emoji for "friendliness" but they
      # reduce code professionalism and can cause encoding issues.
      #
      # @example
      #   # bad
      #   puts "Success! 🎉"
      #   # TODO: Fix this bug 🐛
      #   status = :completed_✅
      #
      #   # good
      #   puts "Success!"
      #   # TODO: Fix this bug
      #   status = :completed
      #
      class NoEmoji < Base
        MSG = "Avoid emoji in code. Use descriptive text instead."

        # Unicode ranges for emoji detection
        # This covers common emoji ranges including:
        # - Emoticons (1F600-1F64F)
        # - Misc symbols (2600-26FF)
        # - Dingbats (2700-27BF)
        # - Transport/map symbols (1F680-1F6FF)
        # - Misc symbols and pictographs (1F300-1F5FF)
        # - Supplemental symbols (1F900-1F9FF)
        # - Flags (1F1E0-1F1FF)
        # - Various other emoji blocks
        EMOJI_PATTERN = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F000}-\u{1F02F}\u{1F0A0}-\u{1F0FF}\u{1FA00}-\u{1FAFF}\u{2300}-\u{23FF}\u{2B50}\u{2B55}\u{203C}\u{2049}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{00A9}\u{00AE}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2614}-\u{2615}\u{2648}-\u{2653}\u{267F}\u{2693}\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270D}\u{270F}\u{2712}\u{2714}\u{2716}\u{271D}\u{2721}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2763}-\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{27BF}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{3030}\u{303D}\u{3297}\u{3299}]/

        def on_new_investigation
          process_comments
        end

        def on_str(node)
          return if allow_in_strings?

          check_for_emoji(node, node.value)
        end

        def on_dstr(node)
          return if allow_in_strings?

          node.each_child_node(:str) do |str_node|
            check_for_emoji(str_node, str_node.value)
          end
        end

        def on_sym(node)
          check_for_emoji(node, node.value.to_s)
        end

        def on_dsym(node)
          node.each_child_node(:str) do |str_node|
            check_for_emoji(str_node, str_node.value)
          end
        end

        private

        def process_comments
          processed_source.comments.each do |comment|
            next unless contains_emoji?(comment.text)

            add_offense(comment)
          end
        end

        def check_for_emoji(node, value)
          return unless contains_emoji?(value)

          add_offense(node)
        end

        def contains_emoji?(text)
          return false if text.nil?

          emoji_matches = text.scan(EMOJI_PATTERN)
          return false if emoji_matches.empty?

          # Filter out allowed emoji
          disallowed = emoji_matches.reject { |e| allowed_emoji.include?(e) }
          disallowed.any?
        end

        def allow_in_strings?
          cop_config.fetch("AllowInStrings", false)
        end

        def allowed_emoji
          @allowed_emoji ||= Array(cop_config.fetch("AllowedEmoji", []))
        end
      end
    end
  end
end
