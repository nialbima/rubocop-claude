# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rubocop_claude/cli'

RSpec.describe RubocopClaude::InitWizard::HooksInstaller do
  let(:tmpdir) { Dir.mktmpdir }
  let!(:original_dir) { Dir.pwd }
  let(:wizard) { RubocopClaude::InitWizard.new }
  let(:installer) { described_class.new(wizard) }

  before do
    Dir.chdir(tmpdir)
    FileUtils.mkdir_p('.claude')
    allow($stdout).to receive(:puts)
  end

  after do
    Dir.chdir(original_dir)
    FileUtils.rm_rf(tmpdir)
  end

  describe '#run' do
    before { wizard.install_hooks = true }

    it 'creates hooks directory, script, and settings' do
      installer.run

      expect(Dir.exist?('.claude/hooks')).to be true
      expect(File.exist?('.claude/hooks/ruby-lint.sh')).to be true
      expect(File.exist?('.claude/settings.local.json')).to be true
    end

    it 'skips creating hooks directory if it exists' do
      FileUtils.mkdir_p('.claude/hooks')

      installer.run

      # Directory already existed, so run completes without error
      expect(Dir.exist?('.claude/hooks')).to be true
    end
  end

  describe 'hook script generation' do
    context 'with rubocop linter (default)' do
      before { wizard.hook_linter = 'rubocop' }

      it 'generates script with binstub preference' do
        installer.run

        content = File.read('.claude/hooks/ruby-lint.sh')
        expect(content).to include('bin/rubocop')
        expect(content).to include('bundle exec rubocop')
        expect(content).to include('$CLAUDE_PROJECT_DIR')
      end
    end

    context 'with standardrb linter' do
      before { wizard.hook_linter = 'standardrb' }

      it 'generates script with standardrb command' do
        installer.run

        content = File.read('.claude/hooks/ruby-lint.sh')
        expect(content).to include('standardrb --fix')
        expect(content).not_to include('bin/rubocop')
      end
    end
  end

  describe 'settings merging' do
    context 'when settings.local.json does not exist' do
      it 'creates new settings file' do
        installer.run

        content = JSON.parse(File.read('.claude/settings.local.json'))
        expect(content['hooks']['PostToolUse']).to be_an(Array)
      end
    end

    context 'when settings.local.json exists without hooks' do
      before do
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'permissions' => {'allow' => []}
        }))
      end

      it 'adds hooks structure and merges' do
        installer.run

        content = JSON.parse(File.read('.claude/settings.local.json'))
        expect(content['permissions']).to eq({'allow' => []})
        expect(content['hooks']['PostToolUse']).to be_an(Array)
      end
    end

    context 'when settings.local.json exists with hooks' do
      before do
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'hooks' => {
            'PostToolUse' => [
              {'matcher' => 'SomeOther', 'hooks' => []}
            ]
          }
        }))
      end

      it 'appends to existing PostToolUse array' do
        installer.run

        content = JSON.parse(File.read('.claude/settings.local.json'))
        expect(content['hooks']['PostToolUse'].size).to eq(2)
      end
    end

    context 'when existing settings has lint hook' do
      before do
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'hooks' => {
            'PostToolUse' => [
              {
                'matcher' => 'Edit',
                'hooks' => [{'command' => 'rubocop -a file.rb'}]
              }
            ]
          }
        }))
      end

      it 'warns about existing lint hook' do
        installer.run

        expect($stdout).to have_received(:puts).with(/Found existing lint hook/)
        expect($stdout).to have_received(:puts).with(/remove duplicate/)
      end
    end

    context 'when existing lint hook command is very long' do
      before do
        long_command = 'bundle exec rubocop -a --format simple ' + ('x' * 100)
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'hooks' => {
            'PostToolUse' => [
              {
                'matcher' => 'Write',
                'hooks' => [{'command' => long_command}]
              }
            ]
          }
        }))
      end

      it 'truncates the warning message' do
        installer.run

        expect($stdout).to have_received(:puts).with(/\.\.\./)
      end
    end

    context 'when existing hook matcher does not match Edit|Write' do
      before do
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'hooks' => {
            'PostToolUse' => [
              {
                'matcher' => 'SomeOtherTool',
                'hooks' => [{'command' => 'rubocop'}]
              }
            ]
          }
        }))
      end

      it 'does not warn about existing lint hook' do
        installer.run

        expect($stdout).not_to have_received(:puts).with(/Found existing lint hook/)
      end
    end

    context 'when existing hook has no hooks array' do
      before do
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'hooks' => {
            'PostToolUse' => [
              {'matcher' => 'Edit'}
            ]
          }
        }))
      end

      it 'handles missing hooks array gracefully' do
        expect { installer.run }.not_to raise_error
      end
    end

    context 'when existing hook command does not match lint patterns' do
      before do
        File.write('.claude/settings.local.json', JSON.pretty_generate({
          'hooks' => {
            'PostToolUse' => [
              {
                'matcher' => 'Edit',
                'hooks' => [{'command' => 'echo hello'}]
              }
            ]
          }
        }))
      end

      it 'does not warn' do
        installer.run

        expect($stdout).not_to have_received(:puts).with(/Found existing lint hook/)
      end
    end
  end
end
