# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'version'

module RubocopClaude
  # CLI for rubocop-claude commands
  class CLI
    TEMPLATES_DIR = File.expand_path('../../templates', __dir__).freeze

    def self.run(args)
      new.run(args)
    end

    def run(args)
      case args.first
      when 'init' then InitWizard.new.run
      when 'version', '-v', '--version' then puts "rubocop-claude #{VERSION}"
      when 'help', '-h', '--help', nil then print_help
      else
        warn "Unknown command: #{args.first}"
        print_help
        exit 1
      end
    end

    private

    def print_help
      puts <<~HELP
        Usage: rubocop-claude <command>

        Commands:
          init      Interactive setup wizard
          version   Show version
          help      Show this help

        Examples:
          rubocop-claude init     # Set up rubocop-claude in current project
          rubocop-claude version  # Show version
      HELP
    end
  end

  # Interactive setup wizard for rubocop-claude
  class InitWizard
    TEMPLATES_DIR = CLI::TEMPLATES_DIR

    def initialize
      @changes = []
      @config_overrides = {}
      @using_standard = false
    end

    def run
      print_welcome
      check_gemfile
      setup_linter_config
      gather_preferences
      create_claude_files
      print_summary
    end

    private

    # =========================================================================
    # Welcome
    # =========================================================================

    def print_welcome
      puts <<~WELCOME
        +-------------------------------------------+
        |  rubocop-claude #{VERSION.ljust(26)}|
        |  AI-focused Ruby linting setup wizard     |
        +-------------------------------------------+

      WELCOME
    end

    # =========================================================================
    # Gemfile
    # =========================================================================

    def check_gemfile
      return unless File.exist?('Gemfile')

      gemfile_content = File.read('Gemfile')
      return if gemfile_content.include?('rubocop-claude')

      return unless prompt_yes?('Add rubocop-claude to Gemfile?', default: true)

      add_to_gemfile
    end

    def add_to_gemfile
      gemfile = File.read('Gemfile')

      # Try to add to development group if it exists
      if gemfile.match?(/group\s+:development.*do/m)
        gemfile.sub!(/^(\s*)(group\s+:development.*?do\s*$)/m) do
          "#{::Regexp.last_match(1)}#{::Regexp.last_match(2)}\n#{::Regexp.last_match(1)}  gem 'rubocop-claude', require: false"
        end
      else
        gemfile += "\ngem 'rubocop-claude', require: false\n"
      end

      File.write('Gemfile', gemfile)
      @changes << 'Added rubocop-claude to Gemfile'
      puts '  Added to Gemfile (run `bundle install`)'
      puts
    end

    # =========================================================================
    # Linter config (StandardRB or RuboCop)
    # =========================================================================

    def setup_linter_config
      config_type = detect_config_type

      case config_type
      when :standard
        setup_standard_config
      when :rubocop
        setup_rubocop_config
      when :none
        create_new_config
      end
    end

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
      @using_standard = true
      puts 'Detected: StandardRB (.standard.yml)'

      config = load_yaml('.standard.yml')
      plugins = config['plugins'] || []

      if plugins.include?('rubocop-claude')
        puts '  rubocop-claude already configured'
      elsif prompt_yes?('  Add rubocop-claude plugin?', default: true)
        config['plugins'] = plugins + ['rubocop-claude']
        save_yaml('.standard.yml', config)
        @changes << 'Added rubocop-claude to .standard.yml plugins'
      end
      puts
    end

    def setup_rubocop_config
      puts 'Detected: RuboCop (.rubocop.yml)'

      config = load_yaml('.rubocop.yml')
      requires = config['require'] || []

      if requires.include?('rubocop-claude')
        puts '  rubocop-claude already configured'
      elsif prompt_yes?('  Add rubocop-claude to require?', default: true)
        config['require'] = requires + ['rubocop-claude']
        save_yaml('.rubocop.yml', config)
        @changes << 'Added rubocop-claude to .rubocop.yml require'
      end
      puts
    end

    def create_new_config
      puts 'No linter config found.'
      choice = prompt_choice(
        'Which linter do you use?',
        {'s' => 'StandardRB', 'r' => 'RuboCop', 'n' => 'Skip'},
        default: 's'
      )

      case choice
      when 's'
        create_standard_config
      when 'r'
        create_rubocop_config
      end
      puts
    end

    def create_standard_config
      config = {'plugins' => ['rubocop-claude']}
      save_yaml('.standard.yml', config)
      @changes << 'Created .standard.yml with rubocop-claude'
      puts '  Created .standard.yml'
    end

    def create_rubocop_config
      config = {'require' => ['rubocop-claude']}
      save_yaml('.rubocop.yml', config)
      @changes << 'Created .rubocop.yml with rubocop-claude'
      puts '  Created .rubocop.yml'
    end

    # =========================================================================
    # Preferences
    # =========================================================================

    def gather_preferences
      puts 'Configuration options:'
      puts

      gather_ai_defaults
      gather_visibility_style
      gather_emoji_preference
      gather_commented_code_preference
      puts
    end

    def gather_ai_defaults
      if @using_standard
        puts '  Metrics cops (MethodLength, ClassLength, etc.) will be enabled.'
        puts '  (StandardRB handles style; we add metrics enforcement)'
        @changes << 'Metrics cops enabled (StandardRB mode)'
      else
        puts '  AI Defaults: Stricter metrics, guard clauses, frozen constants, etc.'
        puts '  (See README "Suggested RuboCop Defaults" for full list)'
        @ai_defaults = prompt_yes?('  Enable AI defaults?', default: true)
        @changes << (@ai_defaults ? 'AI defaults enabled' : 'AI defaults disabled (Claude cops only)')
      end
    end

    def gather_visibility_style
      choice = prompt_choice(
        '  Visibility style?',
        {'g' => 'grouped (private section)', 'm' => 'modifier (private def)'},
        default: 'g'
      )

      style = (choice == 'm') ? 'modifier' : 'grouped'
      @config_overrides['Claude/ExplicitVisibility'] = {'EnforcedStyle' => style}
      @changes << "Visibility style: #{style}"
    end

    def gather_emoji_preference
      @allow_emoji = prompt_yes?('  Allow emoji in strings?', default: false)

      if @allow_emoji
        @config_overrides['Claude/NoFancyUnicode'] = {'AllowInStrings' => true}
        @changes << 'Emoji allowed in strings'
      else
        @changes << 'Emoji not allowed anywhere'
      end
    end

    def gather_commented_code_preference
      choice = prompt_choice(
        '  Flag commented code:',
        {'1' => 'Single lines too', '2' => 'Only multi-line blocks'},
        default: '2'
      )

      min_lines = choice.to_i
      @config_overrides['Claude/NoCommentedCode'] = {'MinLines' => min_lines}
      @changes << "Commented code detection: #{(min_lines == 1) ? "single lines" : "multi-line only"}"
    end

    # =========================================================================
    # Claude files
    # =========================================================================

    def create_claude_files
      puts 'Claude integration files:'
      puts

      create_claude_directory
      create_linting_md
      create_local_config if @config_overrides.any?
    end

    def create_claude_directory
      return if Dir.exist?('.claude')

      FileUtils.mkdir_p('.claude')
      puts '  Created .claude/ directory'
    end

    def create_linting_md
      dest = '.claude/linting.md'
      source = File.join(TEMPLATES_DIR, 'linting.md')

      if File.exist?(dest)
        return unless prompt_yes?("  #{dest} exists. Overwrite?", default: false)
      end

      FileUtils.cp(source, dest)
      @changes << 'Created .claude/linting.md'
      puts "  Created #{dest}"
    end

    def create_local_config
      # Write project-specific overrides to .rubocop_claude.yml
      return if @config_overrides.empty?

      overrides = @config_overrides.dup
      overrides.delete('inherit_from_ai_defaults')

      return if overrides.empty?

      dest = '.rubocop_claude.yml'
      if File.exist?(dest)
        existing = load_yaml(dest)
        overrides = existing.merge(overrides)
      end

      save_yaml(dest, overrides)
      @changes << 'Created .rubocop_claude.yml with your preferences'
      puts "  Created #{dest}"

      # Remind to inherit from it
      puts '  (Add `inherit_from: .rubocop_claude.yml` to your rubocop config)'
    end

    # =========================================================================
    # Summary
    # =========================================================================

    def print_summary
      puts
      puts '-' * 45
      puts 'Setup complete!'
      puts
      puts 'Changes made:'
      @changes.each { |c| puts "  - #{c}" }
      puts
      puts 'Next steps:'
      puts '  1. Run `bundle install` if Gemfile was updated'
      puts '  2. Run `standardrb` or `rubocop` to lint your code'
      puts '  3. Add .claude/linting.md to your AI assistant context'
      puts
    end

    # =========================================================================
    # Helpers
    # =========================================================================

    def prompt_yes?(question, default:)
      suffix = default ? '[Y/n]' : '[y/N]'
      print "#{question} #{suffix} "

      answer = $stdin.gets
      return default if answer.nil?

      normalized = answer.strip.downcase
      return default if normalized.empty?

      normalized == 'y'
    end

    def prompt_choice(question, options, default:)
      options_str = options.map { |k, v| "#{k}=#{v}" }.join(', ')
      print "#{question} (#{options_str}) [#{default}] "

      answer = $stdin.gets
      return default if answer.nil?

      normalized = answer.strip.downcase
      return default if normalized.empty?

      options.key?(normalized) ? normalized : default
    end

    def load_yaml(file)
      return {} unless File.exist?(file)

      YAML.load_file(file) || {}
    end

    def save_yaml(file, data)
      File.write(file, YAML.dump(data))
    end
  end
end
