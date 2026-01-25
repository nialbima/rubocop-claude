# frozen_string_literal: true

require 'rubocop_claude/cli'

RSpec.describe RubocopClaude::InitWizard::PreferencesGatherer do
  let(:wizard) { RubocopClaude::InitWizard.new }
  let(:gatherer) { described_class.new(wizard) }

  before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  describe 'gather_ai_defaults' do
    context 'when not using standard' do
      before { wizard.using_standard = false }

      it 'enables AI defaults when user confirms' do
        allow($stdin).to receive(:gets).and_return("y\n", "g\n", "n\n", "2\n", "n\n")
        gatherer.run

        changes = wizard.instance_variable_get(:@changes)
        expect(changes).to include('AI defaults enabled')
      end

      it 'disables AI defaults when user declines' do
        allow($stdin).to receive(:gets).and_return("n\n", "g\n", "n\n", "2\n", "n\n")
        gatherer.run

        changes = wizard.instance_variable_get(:@changes)
        expect(changes).to include('AI defaults disabled (Claude cops only)')
      end
    end

    context 'when using standard' do
      before { wizard.using_standard = true }

      it 'auto-enables metrics cops without prompting' do
        allow($stdin).to receive(:gets).and_return("g\n", "n\n", "2\n", "n\n")
        gatherer.run

        changes = wizard.instance_variable_get(:@changes)
        expect(changes).to include('Metrics cops enabled (StandardRB mode)')
      end
    end
  end

  describe 'gather_emoji_preference' do
    before { wizard.using_standard = true }

    it 'configures AllowInStrings when user allows emoji' do
      allow($stdin).to receive(:gets).and_return("g\n", "y\n", "2\n", "n\n")
      gatherer.run

      overrides = wizard.instance_variable_get(:@config_overrides)
      expect(overrides['Claude/NoFancyUnicode']).to eq({'AllowInStrings' => true})
    end
  end

  describe 'gather_hook_linter_preference' do
    before { wizard.using_standard = true }

    it 'sets standardrb when user chooses s' do
      allow($stdin).to receive(:gets).and_return("g\n", "n\n", "2\n", "y\n", "s\n")
      gatherer.run

      expect(wizard.hook_linter).to eq('standardrb')
    end
  end
end
