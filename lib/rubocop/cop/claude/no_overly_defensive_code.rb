# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Flags overly defensive coding patterns.
      #
      # AI assistants often add excessive error handling and nil-checking
      # "just in case." This obscures bugs, makes code harder to read,
      # and indicates distrust of the codebase.
      #
      # @example Error swallowing - block form (flagged)
      #   # bad - swallows all errors
      #   begin
      #     do_something
      #   rescue => e
      #     nil
      #   end
      #
      #   # bad - empty rescue body
      #   begin
      #     do_something
      #   rescue
      #   end
      #
      # @example Error swallowing - inline form (flagged)
      #   # bad
      #   result = do_something rescue nil
      #
      # @example Error swallowing - allowed patterns
      #   # good - let errors propagate
      #   do_something
      #
      #   # good - handle meaningfully
      #   begin
      #     do_something
      #   rescue SpecificError => e
      #     log_error(e)
      #     fallback_value
      #   end
      #
      #   # good - specific exceptions with empty body (intentional ignore)
      #   begin
      #     require 'optional_gem'
      #   rescue LoadError
      #     # Optional dependency not available
      #   end
      #
      # @example Excessive safe navigation (flagged when > MaxSafeNavigationChain)
      #   # bad - 2+ chained &. violates design principles
      #   user&.profile&.settings
      #
      # @example Safe navigation - allowed patterns
      #   # good - single &. at system boundary
      #   user&.name
      #
      #   # good - trust your data model
      #   user.profile.settings.notifications
      #
      #   # good - explicit nil check
      #   return unless user
      #   user.profile.settings.notifications
      #
      # @example MaxSafeNavigationChain: 2 (more permissive)
      #   # ok with MaxSafeNavigationChain: 2
      #   user&.profile&.settings
      #
      # @example Pre-safe-navigation nil checks (always flagged)
      #   # bad - defensive nil check before method call
      #   a && a.foo
      #   user && user.name
      #
      # @example AddSafeNavigator: false (default - fail fast)
      #   # autocorrects to direct call (trust the code)
      #   a && a.foo  # => a.foo
      #
      # @example AddSafeNavigator: true (add safe navigation)
      #   # autocorrects to safe navigation
      #   a && a.foo  # => a&.foo
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

        def on_resbody(node)
          # Check for rescue that just returns nil
          return unless swallows_error?(node)

          add_offense(node, message: MSG_SWALLOW)
        end

        # Detect `a && a.foo` and `a.present? && a.foo` patterns
        def on_and(node)
          left, right = *node

          # Right side must be a method call
          return unless right.send_type?

          # Pattern 1: `a.present? && a.foo` → `a.foo`
          if presence_check?(left)
            receiver = left.receiver
            if same_variable?(receiver, right.receiver)
              replacement = build_replacement(right)
              message = format(MSG_PRESENT_CHECK, code: node.source, replacement: replacement)

              add_offense(node, message: message) do |corrector|
                corrector.replace(node, replacement)
              end
              return
            end
          end

          # Pattern 2: `a && a.foo` → `a.foo`
          return unless defensive_nil_check?(left, right)

          replacement = build_replacement(right)
          message = format(MSG_NIL_CHECK, code: node.source, replacement: replacement)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        # Detect `foo.nil? ? default : foo` and `foo ? foo : default` patterns
        def on_if(node)
          return unless node.ternary?

          condition, if_branch, else_branch = *node

          # Pattern 1: `foo.nil? ? default : foo` → `foo || default`
          if nil_check_condition?(condition)
            receiver = condition.receiver
            if same_variable?(receiver, else_branch)
              replacement = "#{receiver.source} || #{if_branch.source}"
              message = format(MSG_NIL_TERNARY, code: node.source, replacement: replacement)

              add_offense(node, message: message) do |corrector|
                corrector.replace(node, replacement)
              end
              return
            end
          end

          # Pattern 2: `foo ? foo : default` → `foo || default`
          if same_variable?(condition, if_branch)
            replacement = "#{condition.source} || #{else_branch.source}"
            message = format(MSG_INVERSE_TERNARY, code: node.source, replacement: replacement)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node, replacement)
            end
          end
        end

        def on_csend(node)
          # Only report on outermost node of a chain to avoid duplicate offenses
          return if node.parent&.csend_type?

          # Count chained safe navigation operators
          chain_length = count_safe_nav_chain(node)
          max_chain = cop_config.fetch('MaxSafeNavigationChain', 1)

          return unless chain_length > max_chain

          add_offense(node, message: format(MSG_CHAIN, count: chain_length))
        end

        private

        def swallows_error?(resbody_node)
          # resbody has: [exception_type, exception_var, body]
          exception_type = resbody_node.children[0]
          body = resbody_node.body

          # If catching specific error types, it's intentional - don't flag
          # Only flag bare `rescue` or `rescue => e` (catches StandardError)
          return false if exception_type && specific_exception_type?(exception_type)

          return true if body.nil?
          return true if body.nil_type?

          # Check for explicit `nil` return
          return body.children.empty? || body.children.first&.nil_type? if body.return_type?

          false
        end

        def specific_exception_type?(exception_node)
          # exception_node can be a single constant or an array of constants
          # We consider it "specific" if it names actual exception classes
          # (not just StandardError or Exception which are too broad)
          case exception_node.type
          when :array
            # Multiple exception types: rescue Foo, Bar
            exception_node.children.all? { |child| specific_exception_class?(child) }
          when :const
            specific_exception_class?(exception_node)
          else
            false
          end
        end

        def specific_exception_class?(const_node)
          return false unless const_node.const_type?

          # Get the constant name (last part of qualified name)
          const_name = const_node.children.last.to_s

          # These are too broad - catching them with nil body is suspicious
          broad_exceptions = %w[Exception StandardError RuntimeError]
          !broad_exceptions.include?(const_name)
        end

        def count_safe_nav_chain(node)
          count = 1
          current = node.receiver

          while current
            case current.type
            when :csend
              count += 1
              current = current.receiver
            when :send
              # Stop counting - regular send breaks the &. chain
              break
            else
              break
            end
          end

          count
        end

        # Check if `left` is the same as the receiver of `right`
        # e.g., `a && a.foo` where left=a, right=a.foo
        def defensive_nil_check?(left, right)
          receiver = right.receiver
          return false unless receiver

          same_variable?(left, receiver)
        end

        def same_variable?(node1, node2)
          return false unless node1 && node2

          node1.source == node2.source
        end

        # Check if node is a `foo.nil?` or `foo.blank?` call
        def nil_check_condition?(node)
          return false unless node.send_type?

          method_name = node.method_name
          %i[nil? blank?].include?(method_name)
        end

        # Check if node is a `foo.present?` call
        def presence_check?(node)
          return false unless node.send_type?

          node.method_name == :present?
        end

        def build_replacement(send_node)
          if add_safe_navigator?
            # Convert `a.foo` to `a&.foo`
            receiver = send_node.receiver.source
            method = send_node.method_name
            args = send_node.arguments.map(&:source).join(', ')

            if send_node.arguments.empty?
              "#{receiver}&.#{method}"
            else
              "#{receiver}&.#{method}(#{args})"
            end
          else
            # Just use the direct call (fail fast)
            send_node.source
          end
        end

        def add_safe_navigator?
          cop_config.fetch('AddSafeNavigator', false)
        end
      end
    end
  end
end
