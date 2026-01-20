# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Enforces visibility keyword placement style.
      #
      # Clear visibility makes code easier to understand at a glance.
      # The modifier style (`private def foo`) makes visibility explicit
      # for each method. The grouped style (`private` on its own line)
      # keeps methods together but requires scrolling to see visibility.
      #
      # @example EnforcedStyle: modifier (default)
      #   # bad - grouped visibility
      #   class Foo
      #     def public_method
      #     end
      #
      #     private
      #
      #     def private_method
      #     end
      #   end
      #
      #   # good - inline visibility modifier
      #   class Foo
      #     def public_method
      #     end
      #
      #     private def private_method
      #     end
      #   end
      #
      # @example EnforcedStyle: grouped
      #   # bad - mixed visibility modifiers
      #   class Foo
      #     def public_method
      #     end
      #
      #     private def private_method
      #     end
      #   end
      #
      #   # good - grouped visibility
      #   class Foo
      #     def public_method
      #     end
      #
      #     private
      #
      #     def private_method
      #     end
      #   end
      #
      class ExplicitVisibility < Base
        extend AutoCorrector

        VISIBILITY_METHODS = %i[private protected public].freeze

        MSG_USE_MODIFIER = "Use explicit visibility. Place `%<visibility>s` before the method definition."
        MSG_USE_GROUPED = "Use grouped visibility. Place `%<visibility>s` on its own line before private methods."

        def on_send(node)
          return unless visibility_declaration?(node)
          return unless node.arguments.empty? # standalone visibility keyword

          # In modifier style, standalone visibility keywords are bad
          return unless enforced_style == :modifier

          # Find methods that follow this visibility declaration
          following_methods = find_following_methods(node)
          return if following_methods.empty?

          visibility = node.method_name
          add_offense(node, message: format(MSG_USE_MODIFIER, visibility: visibility)) do |corrector|
            autocorrect_to_modifier(corrector, node, following_methods, visibility)
          end
        end

        def on_def(node)
          return unless enforced_style == :grouped

          # Check if this def has an inline visibility modifier
          parent = node.parent
          return unless parent&.send_type?
          return unless VISIBILITY_METHODS.include?(parent.method_name)
          return unless parent.arguments.size == 1 # visibility def method_name

          visibility = parent.method_name
          add_offense(parent, message: format(MSG_USE_GROUPED, visibility: visibility))
        end

        private

        def enforced_style
          cop_config.fetch("EnforcedStyle", "modifier").to_sym
        end

        def visibility_declaration?(node)
          return false unless node.send_type?

          VISIBILITY_METHODS.include?(node.method_name) &&
            node.receiver.nil?
        end

        def find_following_methods(visibility_node)
          return [] unless visibility_node.parent

          siblings = visibility_node.parent.children
          visibility_index = siblings.index(visibility_node)
          return [] unless visibility_index

          methods = []
          siblings[(visibility_index + 1)..].each do |sibling|
            break if visibility_declaration?(sibling) && sibling.arguments.empty?

            methods << sibling if sibling.def_type?
          end
          methods
        end

        def autocorrect_to_modifier(corrector, visibility_node, methods, visibility)
          # Remove the standalone visibility line
          corrector.remove(range_with_surrounding_newlines(visibility_node))

          # Add visibility modifier to each following method
          methods.each do |method_node|
            corrector.insert_before(method_node, "#{visibility} ")
          end
        end

        def range_with_surrounding_newlines(node)
          range = node.source_range
          source = processed_source.buffer.source

          # Extend to include trailing newline if present
          end_pos = range.end_pos
          end_pos += 1 if source[end_pos] == "\n"

          # Extend to include leading whitespace on the line
          begin_pos = range.begin_pos
          while begin_pos > 0 && source[begin_pos - 1] =~ /[ \t]/
            begin_pos -= 1
          end

          # Include the newline before if this is on its own line
          if begin_pos > 0 && source[begin_pos - 1] == "\n"
            begin_pos -= 1
          end

          Parser::Source::Range.new(processed_source.buffer, begin_pos, end_pos)
        end
      end
    end
  end
end
