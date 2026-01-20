# frozen_string_literal: true

require 'lint_roller'

module RubocopClaude
  class Plugin < LintRoller::Plugin
    def about
      LintRoller::About.new(
        name: 'rubocop-claude',
        version: VERSION,
        homepage: 'https://github.com/nabm/rubocop-claude',
        description: 'AI-focused Ruby linting - catches common AI coding anti-patterns'
      )
    end

    def supported?(context)
      context.engine == :rubocop
    end

    def rules(_context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: config_path
      )
    end

    private

    def config_path
      File.expand_path('../../config/default.yml', __dir__)
    end
  end
end
