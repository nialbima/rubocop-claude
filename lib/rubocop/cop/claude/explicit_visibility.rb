# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Enforces visibility keyword placement style.
      #
      # The grouped style (`private` on its own line) is the dominant Ruby
      # convention. The modifier style (`private def foo`) is less common.
      #
      # @example EnforcedStyle: grouped (default)
      #   # bad
      #   private def foo; end
      #
      #   # good
      #   private
      #   def foo; end
      #
      # @example EnforcedStyle: modifier
      #   # bad
      #   private
      #   def foo; end
      #
      #   # good
      #   private def foo; end
      #
      class ExplicitVisibility < Base
        extend AutoCorrector

        VISIBILITY_METHODS = %i[private protected public].freeze

        MSG_USE_MODIFIER = 'Use explicit visibility. Place `%<visibility>s` before the method definition.'
        MSG_USE_GROUPED = 'Use grouped visibility. Move method to `%<visibility>s` section.'

        def on_send(node)
          return unless standalone_visibility?(node)
          return unless enforced_style == :modifier

          methods = find_following_methods(node)
          return if methods.empty?

          add_offense(node, message: format(MSG_USE_MODIFIER, visibility: node.method_name)) do |corrector|
            autocorrect_to_modifier(corrector, node, methods)
          end
        end

        def on_def(node)
          return unless enforced_style == :grouped
          return unless inline_visibility?(node.parent)

          visibility = node.parent.method_name
          add_offense(node.parent, message: format(MSG_USE_GROUPED, visibility: visibility)) do |corrector|
            autocorrect_to_grouped(corrector, node, node.parent, visibility)
          end
        end

        private

        def enforced_style
          cop_config.fetch('EnforcedStyle', 'grouped').to_sym
        end

        def standalone_visibility?(node)
          node.send_type? && VISIBILITY_METHODS.include?(node.method_name) &&
            node.receiver.nil? && node.arguments.empty?
        end

        def inline_visibility?(node)
          node&.send_type? && %i[private protected].include?(node.method_name) &&
            node.arguments.size == 1
        end

        def find_following_methods(visibility_node)
          siblings = visibility_node.parent.children
          idx = siblings.index(visibility_node)
          siblings[(idx + 1)..].take_while { |s| !standalone_visibility?(s) }.select(&:def_type?)
        end

        def autocorrect_to_modifier(corrector, visibility_node, methods)
          corrector.remove(range_with_newlines(visibility_node))
          methods.each { |m| corrector.insert_before(m, "#{visibility_node.method_name} ") }
        end

        def autocorrect_to_grouped(corrector, def_node, send_node, visibility)
          class_node = def_node.each_ancestor(:class, :module).first
          return unless class_node

          insert_method_in_section(corrector, class_node, def_node, visibility)
          corrector.remove(range_with_newlines(send_node))
        end

        def insert_method_in_section(corrector, class_node, def_node, visibility)
          section = find_visibility_section(class_node, visibility)
          ind = indent(def_node)

          if section
            pos = last_method_in_section(section)&.source_range || section.source_range
            corrector.insert_after(pos, "\n\n#{ind}#{def_node.source}")
          else
            corrector.insert_before(class_node.loc.end.begin,
              "\n\n#{ind}#{visibility}\n\n#{ind}#{def_node.source}\n")
          end
        end

        def find_visibility_section(class_node, visibility)
          class_node.body.each_child_node(:send).find { |n| n.method_name == visibility && n.arguments.empty? }
        end

        def last_method_in_section(visibility_node)
          siblings = visibility_node.parent.children
          idx = siblings.index(visibility_node)
          siblings[(idx + 1)..].take_while { |s| !standalone_visibility?(s) }
            .reverse.find(&:def_type?)
        end

        def indent(node)
          node.source_range.source_line[/\A\s*/]
        end

        def range_with_newlines(node)
          source = processed_source.buffer.source
          begin_pos = adjust_begin_pos(node.source_range.begin_pos, source)
          end_pos = adjust_end_pos(node.source_range.end_pos, source)
          Parser::Source::Range.new(processed_source.buffer, begin_pos, end_pos)
        end

        def adjust_begin_pos(pos, source)
          pos -= 1 while pos.positive? && source[pos - 1] =~ /[ \t]/
          pos -= 1 if pos.positive? && source[pos - 1] == "\n"
          pos
        end

        def adjust_end_pos(pos, source)
          (source[pos] == "\n") ? pos + 1 : pos
        end
      end
    end
  end
end
