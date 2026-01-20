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
      # @example Swallowing errors
      #   # bad
      #   begin
      #     do_something
      #   rescue => e
      #     nil
      #   end
      #
      #   # bad
      #   do_something rescue nil
      #
      #   # good - let errors propagate or handle meaningfully
      #   do_something
      #
      #   # good - if you must rescue, do something useful
      #   begin
      #     do_something
      #   rescue SpecificError => e
      #     log_error(e)
      #     fallback_value
      #   end
      #
      # @example Excessive safe navigation
      #   # bad - 3+ chained &. on internal objects
      #   user&.profile&.settings&.notifications
      #
      #   # good - trust your data model or fail fast
      #   user.profile.settings.notifications
      #
      #   # good - if nil is expected, handle it explicitly
      #   return unless user
      #   user.profile.settings.notifications
      #
      class NoOverlyDefensiveCode < Base
        MSG_SWALLOW = "Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`."
        MSG_CHAIN = 'Trust internal code. Excessive safe navigation (%<count>d chained `&.`) suggests ' \
                    'uncertain data model. Use explicit nil checks or fix the source.'

        def on_resbody(node)
          # Check for rescue that just returns nil
          return unless swallows_error?(node)

          add_offense(node, message: MSG_SWALLOW)
        end

        def on_csend(node)
          # Only report on outermost node of a chain to avoid duplicate offenses
          return if node.parent&.csend_type?

          # Count chained safe navigation operators
          chain_length = count_safe_nav_chain(node)
          max_chain = cop_config.fetch('MaxSafeNavigationChain', 2)

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
      end
    end
  end
end
