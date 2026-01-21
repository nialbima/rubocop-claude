# frozen_string_literal: true

module RubocopClaude
  class InitWizard
    # Handles linter config detection and setup (StandardRB or RuboCop)
    class LinterConfigurer
      def initialize(wizard)
        @wizard = wizard
      end

      def run
        case detect_config_type
        when :standard then setup_standard_config
        when :rubocop then setup_rubocop_config
        when :none then create_new_config
        end
      end

      private

      def detect_config_type
        if File.exist?('.standard.yml')
          :standard
        elsif File.exist?('.rubocop.yml')
          :rubocop
        else
          :none
        end
      end

      def setup_standard_config
        @wizard.using_standard = true
        puts 'Detected: StandardRB (.standard.yml)'
        add_to_linter_config('.standard.yml', 'plugins', 'plugin')
      end

      def setup_rubocop_config
        puts 'Detected: RuboCop (.rubocop.yml)'
        add_to_linter_config('.rubocop.yml', 'require', 'require')
      end

      def add_to_linter_config(file, key, prompt_label)
        config = @wizard.load_yaml(file)
        existing = config[key] || []

        if existing.include?('rubocop-claude')
          puts '  rubocop-claude already configured'
        elsif @wizard.prompt_yes?("  Add rubocop-claude #{prompt_label}?", default: true)
          config[key] = existing + ['rubocop-claude']
          @wizard.save_yaml(file, config)
          @wizard.add_change("Added rubocop-claude to #{file} #{key}")
        end
        puts
      end

      def create_new_config
        puts 'No linter config found.'
        choice = @wizard.prompt_choice(
          'Which linter do you use?',
          {'s' => 'StandardRB', 'r' => 'RuboCop', 'n' => 'Skip'},
          default: 's'
        )

        case choice
        when 's' then create_standard_config
        when 'r' then create_rubocop_config
        end
        puts
      end

      def create_standard_config
        config = {'plugins' => ['rubocop-claude']}
        @wizard.save_yaml('.standard.yml', config)
        @wizard.add_change('Created .standard.yml with rubocop-claude')
        puts '  Created .standard.yml'
      end

      def create_rubocop_config
        config = {'require' => ['rubocop-claude']}
        @wizard.save_yaml('.rubocop.yml', config)
        @wizard.add_change('Created .rubocop.yml with rubocop-claude')
        puts '  Created .rubocop.yml'
      end
    end
  end
end
