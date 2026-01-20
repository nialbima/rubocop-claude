# frozen_string_literal: true

require 'fileutils'

module RubocopClaude
  class Generator
    TEMPLATES_DIR = File.expand_path('../../templates', __dir__).freeze

    def initialize(project_root)
      @project_root = project_root
    end

    def run
      ensure_directories
      copy_linting_guide
      copy_cop_guides
      update_standard_yml if standard_yml_exists?
      print_summary
    end

    private

    def ensure_directories
      FileUtils.mkdir_p(claude_directory)
      FileUtils.mkdir_p(cops_directory)
    end

    def claude_directory
      File.join(@project_root, '.claude')
    end

    def cops_directory
      File.join(claude_directory, 'cops')
    end

    def copy_linting_guide
      src = File.join(TEMPLATES_DIR, 'linting.md')
      dest = File.join(claude_directory, 'linting.md')
      FileUtils.cp(src, dest)
      puts "Created #{relative_path(dest)}"
    end

    def copy_cop_guides
      cops_src_dir = File.join(TEMPLATES_DIR, 'cops')
      Dir.glob(File.join(cops_src_dir, '*.md')).each do |src|
        filename = File.basename(src)
        dest = File.join(cops_directory, filename)
        FileUtils.cp(src, dest)
        puts "Created #{relative_path(dest)}"
      end
    end

    def standard_yml_exists?
      File.exist?(standard_yml_path)
    end

    def standard_yml_path
      File.join(@project_root, '.standard.yml')
    end

    def update_standard_yml
      content = File.read(standard_yml_path)
      return puts "#{relative_path(standard_yml_path)} already includes rubocop-claude" if content.include?('rubocop-claude')

      File.write(standard_yml_path, add_plugin_to_yaml(content))
      puts "Updated #{relative_path(standard_yml_path)} to include rubocop-claude plugin"
    end

    def add_plugin_to_yaml(content)
      return content.sub(/^(plugins:)\n/, "\\1\n  - rubocop-claude\n") if content.include?('plugins:')

      content.rstrip + "\n\nplugins:\n  - rubocop-claude\n"
    end

    def print_summary
      puts '', 'rubocop-claude initialized!', ''
      puts 'Files created:'
      puts '  .claude/linting.md          - Main linting instructions'
      puts '  .claude/cops/*.md           - Per-cop fix guidance (loaded on-demand)'
      puts '', 'Next steps:'
      puts "  1. Add `gem 'rubocop-claude'` to your Gemfile"
      puts '  2. Run `bin/standardrb` to check for issues'
      puts '', 'When Claude hits a lint error, it reads the relevant cop guide for fix instructions.'
    end

    def relative_path(path)
      path.sub("#{@project_root}/", '')
    end
  end
end
