# frozen_string_literal: true

module RubocopClaude
  class InitWizard
    # Handles gathering user preferences for cop configuration
    class PreferencesGatherer
      def initialize(wizard)
        @wizard = wizard
      end

      def run
        puts 'Configuration options:'
        puts

        gather_ai_defaults
        gather_visibility_style
        gather_emoji_preference
        gather_commented_code_preference
        gather_hooks_preference
        puts
      end

      private

      def gather_ai_defaults
        if @wizard.using_standard
          puts '  Metrics cops (MethodLength, ClassLength, etc.) will be enabled.'
          puts '  (StandardRB handles style; we add metrics enforcement)'
          @wizard.add_change('Metrics cops enabled (StandardRB mode)')
        else
          puts '  AI Defaults: Stricter metrics, guard clauses, frozen constants, etc.'
          puts '  (See README "Suggested RuboCop Defaults" for full list)'
          ai_defaults = @wizard.prompt_yes?('  Enable AI defaults?', default: true)
          @wizard.add_change(ai_defaults ? 'AI defaults enabled' : 'AI defaults disabled (Claude cops only)')
        end
      end

      def gather_visibility_style
        choice = @wizard.prompt_choice(
          '  Visibility style?',
          {'g' => 'grouped (private section)', 'm' => 'modifier (private def)'},
          default: 'g'
        )

        style = (choice == 'm') ? 'modifier' : 'grouped'
        @wizard.add_config_override('Claude/ExplicitVisibility', {'EnforcedStyle' => style})
        @wizard.add_change("Visibility style: #{style}")
      end

      def gather_emoji_preference
        allow_emoji = @wizard.prompt_yes?('  Allow emoji in strings?', default: false)

        if allow_emoji
          @wizard.add_config_override('Claude/NoFancyUnicode', {'AllowInStrings' => true})
          @wizard.add_change('Emoji allowed in strings')
        else
          @wizard.add_change('Emoji not allowed anywhere')
        end
      end

      def gather_commented_code_preference
        choice = @wizard.prompt_choice(
          '  Flag commented code:',
          {'1' => 'Single lines too', '2' => 'Only multi-line blocks'},
          default: '2'
        )

        min_lines = choice.to_i
        @wizard.add_config_override('Claude/NoCommentedCode', {'MinLines' => min_lines})
        @wizard.add_change("Commented code detection: #{(min_lines == 1) ? "single lines" : "multi-line only"}")
      end

      def gather_hooks_preference
        puts
        puts '  Claude Code hooks auto-lint Ruby files after each edit.'
        @wizard.install_hooks = @wizard.prompt_yes?('  Install Claude Code hooks?', default: false)
        return unless @wizard.install_hooks

        gather_hook_linter_preference
        @wizard.add_change("Claude Code hooks enabled (#{@wizard.hook_linter})")
      end

      def gather_hook_linter_preference
        choice = @wizard.prompt_choice(
          '  Linter for hooks?',
          {'r' => 'RuboCop', 's' => 'StandardRB'},
          default: 'r'
        )

        @wizard.hook_linter = (choice == 's') ? 'standardrb' : 'rubocop'
      end
    end
  end
end
