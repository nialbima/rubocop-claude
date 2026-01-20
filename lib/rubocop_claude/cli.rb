# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'version'

module RubocopClaude
  # CLI for rubocop-claude commands
  class CLI
    LINTING_TEMPLATE = File.expand_path('../../templates/linting.md', __dir__).freeze

    def self.run(args)
      new.run(args)
    end

    def run(args)
      case args.first
      when 'init' then init_command
      when 'version', '-v', '--version' then puts "rubocop-claude #{VERSION}"
      when 'help', '-h', '--help', nil then print_help
      else
        warn "Unknown command: #{args.first}"
        print_help
        exit 1
      end
    end

    private

    def init_command
      puts 'Initializing rubocop-claude...'
      puts
      create_linting_md
      update_standard_yml
      update_rubocop_yml
      puts
      puts 'Done! Run `standardrb` or `rubocop` to lint your code.'
    end

    def create_linting_md
      linting_path = '.claude/linting.md'
      return if File.exist?(linting_path) && !prompt_yes?("#{linting_path} already exists. Overwrite?", default: false)

      FileUtils.mkdir_p('.claude')
      FileUtils.cp(LINTING_TEMPLATE, linting_path)
      puts "Created #{linting_path}"
    end

    def update_standard_yml
      return unless File.exist?('.standard.yml')

      update_yaml_config('.standard.yml', 'plugins', 'rubocop-claude')
    end

    def update_rubocop_yml
      return if File.exist?('.standard.yml')
      return unless File.exist?('.rubocop.yml')

      update_yaml_config('.rubocop.yml', 'require', 'rubocop-claude')
    end

    def update_yaml_config(file, key, value)
      config = YAML.load_file(file) || {}
      items = config[key] || []

      if items.include?(value)
        puts "#{file} already includes #{value}"
        return
      end

      return unless prompt_yes?("Add #{value} to #{file}?", default: true)

      config[key] = items + [value]
      File.write(file, YAML.dump(config))
      puts "Updated #{file}"
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

    def print_help
      puts <<~HELP
        Usage: rubocop-claude <command>

        Commands:
          init      Set up rubocop-claude in the current project
          version   Show version
          help      Show this help

        Examples:
          rubocop-claude init     # Interactive setup wizard
          rubocop-claude version  # Show version
      HELP
    end
  end
end
