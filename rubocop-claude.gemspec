# frozen_string_literal: true

require_relative 'lib/rubocop_claude/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-claude'
  spec.version = RubocopClaude::VERSION
  spec.authors = ['Nicholas Marshall']
  spec.email = ['nialbima@users.noreply.github.com']

  spec.summary = 'AI-focused Ruby linting via StandardRB plugin'
  spec.description = 'A Rubocop/StandardRB plugin providing automated Rubocop foot-rake feedback to AI coding agents.'
  spec.homepage = 'https://github.com/nabm/rubocop-claude'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['default_lint_roller_plugin'] = 'RubocopClaude::Plugin'

  spec.files = Dir.glob('{config,lib,templates,exe}/**/*') + %w[
    LICENSE.txt
    README.md
    CHANGELOG.md
    rubocop-claude.gemspec
  ]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'lint_roller', '~> 1.1'
  spec.add_dependency 'rubocop', '>= 1.50'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-packaging', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.9'
  spec.add_development_dependency 'standard', '~> 1.40'
end
