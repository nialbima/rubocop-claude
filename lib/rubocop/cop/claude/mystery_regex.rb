# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Enforces that long regexes are extracted to named constants.
      #
      # Complex regexes are hard to understand at a glance. Extracting them
      # to a named constant with a descriptive name (and optionally a comment)
      # makes the intent clear.
      #
      # @example MaxLength: 25 (default)
      #   # bad - what does this match?
      #   text.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
      #
      #   # good - intent is clear from the name
      #   EMAIL_PATTERN = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
      #   text.match?(EMAIL_PATTERN)
      #
      #   # good - short regexes are fine inline
      #   text.match?(/\A\d+\z/)
      #
      #   # good - in specs, let blocks provide naming
      #   let(:email_pattern) { /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/ }
      #
      class MysteryRegex < Base
        MSG = 'Extract long regex to a named constant. ' \
              'Complex patterns deserve descriptive names.'

        def on_regexp(node)
          return if node.content.length <= max_length
          return if inside_named_assignment?(node)

          add_offense(node)
        end

        private

        def max_length
          @max_length ||= cop_config.fetch('MaxLength', 25)
        end

        def inside_named_assignment?(node)
          inside_constant_assignment?(node) || inside_let_block?(node)
        end

        def inside_constant_assignment?(node)
          node.each_ancestor(:casgn).any?
        end

        def inside_let_block?(node)
          node.each_ancestor(:block).any? do |block|
            send_node = block.send_node
            send_node.method?(:let) || send_node.method?(:let!)
          end
        end
      end
    end
  end
end
