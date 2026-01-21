# frozen_string_literal: true

require 'json'

module RubocopClaude
  class InitWizard
    # Handles installing Claude Code hooks for auto-linting
    class HooksInstaller
      def initialize(wizard)
        @wizard = wizard
      end

      def run
        create_hooks_directory
        create_hook_script
        create_hooks_settings
      end

      private

      def create_hooks_directory
        return if Dir.exist?('.claude/hooks')

        FileUtils.mkdir_p('.claude/hooks')
      end

      def create_hook_script
        dest = '.claude/hooks/ruby-lint.sh'
        source = File.join(CLI::TEMPLATES_DIR, 'hooks', 'ruby-lint.sh')
        FileUtils.cp(source, dest)
        FileUtils.chmod(0o755, dest)
        @wizard.add_change('Created .claude/hooks/ruby-lint.sh')
        puts "  Created #{dest}"
      end

      def create_hooks_settings
        dest = '.claude/settings.local.json'
        source = File.join(CLI::TEMPLATES_DIR, 'hooks', 'settings.local.json')

        if File.exist?(dest)
          merge_hooks_settings(dest, source)
        else
          FileUtils.cp(source, dest)
          @wizard.add_change('Created .claude/settings.local.json with hooks')
          puts "  Created #{dest}"
        end
      end

      def merge_hooks_settings(dest, source)
        existing = JSON.parse(File.read(dest))
        new_hooks = JSON.parse(File.read(source))

        existing['hooks'] ||= {}
        existing['hooks']['PostToolUse'] ||= []
        existing['hooks']['PostToolUse'].concat(new_hooks['hooks']['PostToolUse'])

        File.write(dest, JSON.pretty_generate(existing))
        @wizard.add_change('Added Ruby lint hook to .claude/settings.local.json')
        puts "  Updated #{dest}"
      end
    end
  end
end
