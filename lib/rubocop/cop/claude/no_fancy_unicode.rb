# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Detects non-standard Unicode characters that may cause issues.
      #
      # Flags characters outside the standard set of language characters
      # and keyboard symbols. This catches emoji, fancy typography (curly
      # quotes, em-dashes), and mathematical symbols that look like ASCII
      # operators but aren't.
      #
      # The allowed character set is:
      # - Letters from any script (Latin, Chinese, Japanese, Cyrillic, etc.)
      # - Numbers from any script
      # - Combining marks (for accented characters)
      # - Standard ASCII printable characters (keyboard symbols)
      # - Whitespace
      #
      # @safety
      #   This cop's autocorrection removes the offending character, which
      #   may change the meaning of strings. Review the changes carefully.
      #
      # @example AllowInStrings: false (default)
      #   # bad - emoji
      #   puts "Success! 🎉"
      #
      #   # bad - fancy curly quotes
      #   puts "Hello world"
      #
      #   # bad - mathematical symbols instead of ASCII
      #   return false if x ≠ y
      #
      #   # bad - em-dash instead of double-hyphen
      #   # See section 3 — Implementation
      #
      #   # good - standard ASCII
      #   puts "Success!"
      #   puts "Hello world"
      #   return false if x != y
      #   # See section 3 -- Implementation
      #
      #   # good - international text
      #   greeting = "你好"
      #   message = "Привет мир"
      #   text = "café"
      #
      # @example AllowInStrings: true
      #   # bad - still catches in comments
      #   # TODO: Fix bug 🐛
      #
      #   # bad - still catches in symbols
      #   status = :"done_✅"
      #
      #   # good - strings can have fancy unicode
      #   puts "Success! 🎉"
      #   message = "Use → for arrows"
      #
      # @example AllowedUnicode: ['→', '←', '•']
      #   # bad - not in allowed list
      #   puts "Check: ✅"
      #
      #   # good - in allowed list
      #   # Click → to continue
      #   puts "• Item one"
      #
      # @example Allowed character set
      #   \p{L}       # Letters (any script: Latin, Chinese, Japanese, Cyrillic, etc.)
      #   \p{M}       # Marks (combining diacritics for accented characters)
      #   \p{N}       # Numbers (any script)
      #   \x20-\x7E   # ASCII printable (space through tilde - all keyboard symbols)
      #   \t\n\r      # Whitespace
      #
      # @see https://www.compart.com/en/unicode/category
      class NoFancyUnicode < Base
        extend AutoCorrector

        MSG = 'Avoid fancy Unicode `%<char>s` (U+%<codepoint>s). ' \
              'Use standard ASCII or add to AllowedUnicode.'

        ALLOWED_PATTERN = /[\p{L}\p{M}\p{N}\x20-\x7E\t\n\r]/

        def on_new_investigation
          process_comments unless allow_in_comments?
        end

        def on_str(node)
          return if allow_in_strings?

          check_for_fancy_unicode(node, node.value)
        end

        def on_dstr(node)
          return if allow_in_strings?

          node.each_child_node(:str) do |str_node|
            check_for_fancy_unicode(str_node, str_node.value)
          end
        end

        def on_sym(node)
          check_for_fancy_unicode(node, node.value.to_s)
        end

        def on_dsym(node)
          node.each_child_node(:str) do |str_node|
            check_for_fancy_unicode(str_node, str_node.value)
          end
        end

        private

        def process_comments
          processed_source.comments.each do |comment|
            fancy_chars = find_fancy_unicode(comment.text)
            next if fancy_chars.empty?

            # Report first char but fix ALL chars in one correction
            add_offense(comment, message: format_message(fancy_chars.first)) do |corrector|
              corrector.replace(comment, clean_text(comment.text, fancy_chars))
            end
          end
        end

        def check_for_fancy_unicode(node, value)
          fancy_chars = find_fancy_unicode(value)
          return if fancy_chars.empty?

          # Report first char but fix ALL chars in one correction
          add_offense(node, message: format_message(fancy_chars.first)) do |corrector|
            corrector.replace(node, clean_text(node.source, fancy_chars))
          end
        end

        def clean_text(text, chars)
          result = text.dup
          Array(chars).each { |char| result.gsub!(char, '') }
          result
            .gsub(/_+\z/, '')          # Remove trailing underscores at end
            .gsub(/_+(['"])/, '\1')    # Remove trailing underscores before closing quote
            .gsub(/\s{2,}/, ' ')       # Collapse multiple spaces to single space
            .gsub(/\s+(['"])/, '\1')   # Remove trailing space before closing quote
            .gsub(/\s+\z/, '')         # Remove trailing whitespace at end
        end

        def find_fancy_unicode(text)
          # Find all characters that don't match the allowed pattern
          fancy = text.chars.reject { |char| char.match?(ALLOWED_PATTERN) }

          # Filter out explicitly allowed unicode characters
          fancy.reject { |char| allowed_unicode.include?(char) }.uniq
        end

        def format_message(char)
          codepoint = char.ord.to_s(16).upcase.rjust(4, '0')
          format(MSG, char: char, codepoint: codepoint)
        end

        def allow_in_strings?
          cop_config.fetch('AllowInStrings', false)
        end

        def allow_in_comments?
          cop_config.fetch('AllowInComments', false)
        end

        def allowed_unicode
          @allowed_unicode ||= Array(cop_config.fetch('AllowedUnicode', []))
        end
      end
    end
  end
end
