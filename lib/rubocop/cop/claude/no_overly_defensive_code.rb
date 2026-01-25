# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Flags overly defensive coding patterns.
      #
      # AI assistants often add excessive error handling and nil-checking
      # "just in case." This obscures bugs and indicates distrust of the codebase.
      #
      # @example Error swallowing (flagged)
      #   # bad
      #   begin; do_something; rescue => e; nil; end
      #   result = do_something rescue nil
      #
      # @example Excessive safe navigation (flagged)
      #   # bad - 2+ chained &.
      #   user&.profile&.settings
      #
      # @example Defensive nil checks (flagged)
      #   # bad
      #   a && a.foo
      #   a.present? && a.foo
      #   foo.nil? ? default : foo
      #   foo ? foo : default
      #
      class NoOverlyDefensiveCode < Base
        extend AutoCorrector

        MSG_SWALLOW = "Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`."
        MSG_CHAIN = 'Trust internal code. Excessive safe navigation (%<count>d chained `&.`) suggests ' \
                    'uncertain data model. Use explicit nil checks or fix the source.'
        MSG_NIL_CHECK = 'Trust internal code. `%<code>s` is a defensive nil check. ' \
                        'Use `%<replacement>s` instead.'
        MSG_NIL_TERNARY = 'Trust internal code. `%<code>s` is a verbose nil check. ' \
                          'Use `%<replacement>s` instead.'
        MSG_INVERSE_TERNARY = 'Trust internal code. `%<code>s` is verbose. ' \
                              'Use `%<replacement>s` instead.'
        MSG_PRESENT_CHECK = 'Trust internal code. `%<code>s` is a defensive presence check. ' \
                            'Use `%<replacement>s` instead.'

        BROAD_EXCEPTIONS = %w[Exception StandardError RuntimeError].freeze

        def on_resbody(node)
          add_offense(node, message: MSG_SWALLOW) if swallows_error?(node)
        end

        def on_and(node)
          left, right = *node
          return unless right.send_type?

          check_presence_pattern(node, left, right) || check_nil_check_pattern(node, left, right)
        end

        def on_if(node)
          return unless node.ternary?

          condition, if_branch, else_branch = *node
          check_nil_ternary(node, condition, if_branch, else_branch) ||
            check_inverse_ternary(node, condition, if_branch, else_branch)
        end

        def on_csend(node)
          return if node.parent&.csend_type?

          chain_length = count_safe_nav_chain(node)
          return unless chain_length > max_safe_navigation_chain

          add_offense(node, message: format(MSG_CHAIN, count: chain_length))
        end

        private

        # Pattern: `a.present? && a.foo` -> `a.foo`
        def check_presence_pattern(node, left, right)
          return unless left.send_type? && left.method_name == :present?
          return unless same_variable?(left.receiver, right.receiver)

          register_offense(node, build_replacement(right), MSG_PRESENT_CHECK)
        end

        # Pattern: `a && a.foo` -> `a.foo`
        def check_nil_check_pattern(node, left, right)
          return unless right.receiver && same_variable?(left, right.receiver)

          register_offense(node, build_replacement(right), MSG_NIL_CHECK)
        end

        # Pattern: `foo.nil? ? default : foo` -> `foo || default`
        def check_nil_ternary(node, condition, if_branch, else_branch)
          return unless condition.send_type? && %i[nil? blank?].include?(condition.method_name)
          return unless same_variable?(condition.receiver, else_branch)

          register_offense(node, "#{condition.receiver.source} || #{if_branch.source}", MSG_NIL_TERNARY)
        end

        # Pattern: `foo ? foo : default` -> `foo || default`
        def check_inverse_ternary(node, condition, if_branch, else_branch)
          return unless same_variable?(condition, if_branch)

          register_offense(node, "#{condition.source} || #{else_branch.source}", MSG_INVERSE_TERNARY)
        end

        def register_offense(node, replacement, msg_template)
          message = format(msg_template, code: node.source, replacement: replacement)
          add_offense(node, message: message) { |corrector| corrector.replace(node, replacement) }
        end

        def swallows_error?(resbody_node)
          exception_type, _var, body = *resbody_node
          return false if exception_type && specific_exception?(exception_type)

          body.nil? || body.nil_type? || empty_return?(body)
        end

        def empty_return?(body)
          body.return_type? && (body.children.empty? || body.children.first.nil_type?)
        end

        def specific_exception?(exception_node)
          exception_node.children.all? { |c| specific_exception_class?(c) }
        end

        def specific_exception_class?(const_node)
          const_node.const_type? && !BROAD_EXCEPTIONS.include?(const_node.children.last.to_s)
        end

        def count_safe_nav_chain(node)
          count = 1
          current = node.receiver
          while current.csend_type?
            count += 1
            current = current.receiver
          end
          count
        end

        def same_variable?(node1, node2)
          node1 && node2 && node1.source == node2.source
        end

        def build_replacement(send_node)
          return send_node.source unless add_safe_navigator?

          args = send_node.arguments.map(&:source).join(', ')
          base = "#{send_node.receiver.source}&.#{send_node.method_name}"
          send_node.arguments.empty? ? base : "#{base}(#{args})"
        end

        def add_safe_navigator?
          @add_safe_navigator ||= cop_config.fetch('AddSafeNavigator', false)
        end

        def max_safe_navigation_chain
          @max_safe_navigation_chain ||= cop_config.fetch('MaxSafeNavigationChain', 1)
        end
      end
    end
  end
end
