# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'version'
require_relative 'init_wizard/linter_configurer'
require_relative 'init_wizard/preferences_gatherer'

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
    DEVELOPMENT_GROUP_PATTERN = /group\s+:development.*do/m
    DEVELOPMENT_GROUP_CAPTURE = /^(\s*)(group\s+:development.*?do\s*$)/m

    attr_accessor :using_standard

    def initialize
      @changes = []
      @config_overrides = {}
      @using_standard = false
    end

    def run
      print_welcome
      check_gemfile
      LinterConfigurer.new(self).run
      PreferencesGatherer.new(self).run
      create_claude_files
      print_summary
    end

    def add_change(description)
      @changes << description
    end

    def add_config_override(cop, settings)
      @config_overrides[cop] = settings
    end

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

    private

    def print_welcome
      puts <<~WELCOME
        +-------------------------------------------+
        |  rubocop-claude #{VERSION.ljust(26)}|
        |  AI-focused Ruby linting setup wizard     |
        +-------------------------------------------+

      WELCOME
    end

    def check_gemfile
      return unless File.exist?('Gemfile')

      gemfile_content = File.read('Gemfile')
      return if gemfile_content.include?('rubocop-claude')
      return unless prompt_yes?('Add rubocop-claude to Gemfile?', default: true)

      add_to_gemfile
    end

    def add_to_gemfile
      gemfile = File.read('Gemfile')
      File.write('Gemfile', insert_gem_into_gemfile(gemfile))
      @changes << 'Added rubocop-claude to Gemfile'
      puts '  Added to Gemfile (run `bundle install`)'
      puts
    end

    def insert_gem_into_gemfile(content)
      gem_line = "gem 'rubocop-claude', require: false"
      return content + "\n#{gem_line}\n" unless content.match?(DEVELOPMENT_GROUP_PATTERN)

      content.sub(DEVELOPMENT_GROUP_CAPTURE) do
        "#{::Regexp.last_match(1)}#{::Regexp.last_match(2)}\n#{::Regexp.last_match(1)}  #{gem_line}"
      end
    end

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
      overrides = build_config_overrides
      return if overrides.empty?

      dest = '.rubocop_claude.yml'
      save_yaml(dest, merge_with_existing(dest, overrides))
      @changes << 'Created .rubocop_claude.yml with your preferences'
      puts "  Created #{dest}"
      puts '  (Add `inherit_from: .rubocop_claude.yml` to your rubocop config)'
    end

    def build_config_overrides
      overrides = @config_overrides.dup
      overrides.delete('inherit_from_ai_defaults')
      overrides
    end

    def merge_with_existing(file, overrides)
      return overrides unless File.exist?(file)

      load_yaml(file).merge(overrides)
    end

    def print_summary
      puts '', '-' * 45, 'Setup complete!', ''
      print_changes
      print_next_steps
    end

    def print_changes
      puts 'Changes made:'
      @changes.each { |c| puts "  - #{c}" }
      puts
    end

    def print_next_steps
      puts <<~STEPS
        Next steps:
          1. Run `bundle install` if Gemfile was updated
          2. Run `standardrb` or `rubocop` to lint your code
          3. Add .claude/linting.md to your AI assistant context
      STEPS
    end
  end
end
