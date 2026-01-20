# frozen_string_literal: true

module RuboCop
  module Cop
    module Claude
      # Flags method parameters that shadow instance variables.
      #
      # When a parameter has the same name as an instance variable used
      # in the class, it creates confusion about which is being referenced.
      # Use a different parameter name for clarity.
      #
      # @example
      #   # bad - parameter `name` shadows `@name`
      #   class User
      #     def initialize(name)
      #       @name = name
      #     end
      #
      #     def update(name)  # shadows @name
      #       @name = name
      #     end
      #   end
      #
      #   # good - use descriptive parameter name
      #   class User
      #     def initialize(name)
      #       @name = name
      #     end
      #
      #     def update(new_name)
      #       @name = new_name
      #     end
      #   end
      #
      #   # good - initialize is exempt (common pattern)
      #   class User
      #     def initialize(name)
      #       @name = name
      #     end
      #   end
      #
      class MethodParameterShadowing < Base
        MSG = "Parameter `%<param>s` shadows instance variable `@%<param>s`. Use a different name."

        # These methods commonly use parameter names matching ivars
        # initialize and setup are the canonical "first assignment" methods
        EXEMPT_METHODS = %i[initialize setup].freeze

        def on_class(node)
          @class_ivars = Set.new
          collect_instance_variables(node)
        end

        def on_module(node)
          @class_ivars = Set.new
          collect_instance_variables(node)
        end

        def on_def(node)
          return if EXEMPT_METHODS.include?(node.method_name)
          return unless @class_ivars&.any?

          check_parameters(node)
        end

        private

        def collect_instance_variables(class_node)
          class_node.each_descendant(:ivasgn, :ivar) do |node|
            ivar_name = node.children.first.to_s.delete_prefix("@")
            @class_ivars << ivar_name
          end
        end

        def check_parameters(method_node)
          method_node.arguments.each do |arg|
            next unless arg.arg_type? || arg.optarg_type? || arg.kwarg_type? || arg.kwoptarg_type?

            param_name = arg.children.first.to_s
            next unless @class_ivars.include?(param_name)

            add_offense(arg, message: format(MSG, param: param_name))
          end
        end
      end
    end
  end
end
