# frozen_string_literal: true

RSpec.describe 'Plugin loading', :integration do
  describe 'rubocop-claude entry point' do
    it 'loads without error' do
      expect { require 'rubocop-claude' }.not_to raise_error
    end

    it 'defines RubocopClaude module' do
      require 'rubocop-claude'
      expect(defined?(RubocopClaude)).to eq('constant')
    end

    it 'defines all Claude cops' do
      require 'rubocop-claude'

      expected_cops = %w[
        RuboCop::Cop::Claude::NoFancyUnicode
        RuboCop::Cop::Claude::TaggedComments
        RuboCop::Cop::Claude::NoCommentedCode
        RuboCop::Cop::Claude::NoBackwardsCompatHacks
        RuboCop::Cop::Claude::NoOverlyDefensiveCode
        RuboCop::Cop::Claude::ExplicitVisibility
        RuboCop::Cop::Claude::MysteryRegex
      ]

      expected_cops.each do |cop_class|
        expect(Object.const_get(cop_class)).to be_a(Class)
      end
    end
  end

  describe 'LintRoller plugin' do
    before { require 'rubocop-claude' }

    it 'defines Plugin class' do
      expect(defined?(RubocopClaude::Plugin)).to eq('constant')
    end

    it 'inherits from LintRoller::Plugin' do
      expect(RubocopClaude::Plugin.superclass).to eq(LintRoller::Plugin)
    end

    it 'returns valid about info' do
      plugin = RubocopClaude::Plugin.new
      about = plugin.about

      expect(about.name).to eq('rubocop-claude')
      expect(about.version).to eq(RubocopClaude::VERSION)
      expect(about.homepage).to be_a(String)
    end

    it 'supports rubocop engine' do
      plugin = RubocopClaude::Plugin.new
      context = double(engine: :rubocop)

      expect(plugin.supported?(context)).to be true
    end

    it 'does not support other engines' do
      plugin = RubocopClaude::Plugin.new
      context = double(engine: :other)

      expect(plugin.supported?(context)).to be false
    end

    it 'returns rules pointing to config file' do
      plugin = RubocopClaude::Plugin.new
      context = double(engine: :rubocop)
      rules = plugin.rules(context)

      expect(rules.type).to eq(:path)
      expect(rules.config_format).to eq(:rubocop)
      expect(File.exist?(rules.value)).to be true
    end
  end

  describe 'RuboCop integration' do
    it 'registers Claude cops with RuboCop' do
      require 'rubocop-claude'

      claude_cops = RuboCop::Cop::Registry.global.select do |cop|
        cop.cop_name.start_with?('Claude/')
      end

      expect(claude_cops.size).to eq(7)
    end

    it 'can run rubocop with Claude cops' do
      require 'rubocop-claude'

      # Create a temp file with a violation
      require 'tempfile'
      file = Tempfile.new(['test', '.rb'])
      file.write("puts 'Hello! 🚀'\n")
      file.close

      config = RuboCop::ConfigStore.new
      runner = RuboCop::Runner.new({}, config)

      # Should not raise
      expect { runner.run([file.path]) }.not_to raise_error
    ensure
      file&.unlink
    end
  end

  describe 'gemspec metadata' do
    it 'specifies default_lint_roller_plugin' do
      gemspec_path = File.expand_path('../../../rubocop-claude.gemspec', __dir__)
      gemspec_content = File.read(gemspec_path)

      expect(gemspec_content).to include("default_lint_roller_plugin")
      expect(gemspec_content).to include("RubocopClaude::Plugin")
    end
  end
end
