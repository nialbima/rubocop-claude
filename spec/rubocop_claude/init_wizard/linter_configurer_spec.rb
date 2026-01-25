# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rubocop_claude/cli'

RSpec.describe RubocopClaude::InitWizard::LinterConfigurer do
  let(:tmpdir) { Dir.mktmpdir }
  let!(:original_dir) { Dir.pwd }
  let(:wizard) { RubocopClaude::InitWizard.new }
  let(:configurer) { described_class.new(wizard) }

  before do
    Dir.chdir(tmpdir)
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  after do
    Dir.chdir(original_dir)
    FileUtils.rm_rf(tmpdir)
  end

  describe '#run' do
    context 'when .standard.yml exists' do
      before do
        File.write('.standard.yml', YAML.dump({'plugins' => []}))
        allow($stdin).to receive(:gets).and_return("y\n")
      end

      it 'detects StandardRB and sets using_standard' do
        configurer.run

        expect(wizard.using_standard).to be true
      end

      it 'adds rubocop-claude plugin when user confirms' do
        configurer.run

        content = YAML.load_file('.standard.yml')
        expect(content['plugins']).to include('rubocop-claude')
      end
    end

    context 'when .standard.yml already has rubocop-claude' do
      before do
        File.write('.standard.yml', YAML.dump({'plugins' => ['rubocop-claude']}))
      end

      it 'skips adding and reports already configured' do
        configurer.run

        expect($stdout).to have_received(:puts).with('  rubocop-claude already configured')
      end
    end

    context 'when .rubocop.yml exists' do
      before do
        File.write('.rubocop.yml', YAML.dump({'require' => []}))
        allow($stdin).to receive(:gets).and_return("y\n")
      end

      it 'detects RuboCop and does not set using_standard' do
        configurer.run

        expect(wizard.using_standard).to be false
      end

      it 'adds rubocop-claude require when user confirms' do
        configurer.run

        content = YAML.load_file('.rubocop.yml')
        expect(content['require']).to include('rubocop-claude')
      end
    end

    context 'when .rubocop.yml already has rubocop-claude' do
      before do
        File.write('.rubocop.yml', YAML.dump({'require' => ['rubocop-claude']}))
      end

      it 'skips adding and reports already configured' do
        configurer.run

        expect($stdout).to have_received(:puts).with('  rubocop-claude already configured')
      end
    end

    context 'when user declines to add plugin' do
      before do
        File.write('.standard.yml', YAML.dump({'plugins' => []}))
        allow($stdin).to receive(:gets).and_return("n\n")
      end

      it 'does not modify the config file' do
        configurer.run

        content = YAML.load_file('.standard.yml')
        expect(content['plugins']).to be_empty
      end
    end

    context 'when no config exists and user chooses skip' do
      before do
        allow($stdin).to receive(:gets).and_return("n\n")
      end

      it 'does not create any config file' do
        configurer.run

        expect(File.exist?('.standard.yml')).to be false
        expect(File.exist?('.rubocop.yml')).to be false
      end
    end

    context 'when no config exists and user chooses RuboCop' do
      before do
        allow($stdin).to receive(:gets).and_return("r\n")
      end

      it 'creates .rubocop.yml' do
        configurer.run

        expect(File.exist?('.rubocop.yml')).to be true
        content = YAML.load_file('.rubocop.yml')
        expect(content['require']).to include('rubocop-claude')
      end
    end
  end
end
