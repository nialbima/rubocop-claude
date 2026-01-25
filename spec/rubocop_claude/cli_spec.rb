# frozen_string_literal: true

require 'rubocop_claude/cli'

RSpec.describe RubocopClaude::CLI do
  let(:cli) { described_class.new }
  let(:version_pattern) { /rubocop-claude \d+\.\d+\.\d+/ }

  before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  describe '.run' do
    it 'instantiates and runs' do
      described_class.run(['help'])

      expect($stdout).to have_received(:puts).with(/Usage: rubocop-claude/)
    end
  end

  describe '#run' do
    context 'with version command' do
      it 'prints version for version' do
        cli.run(['version'])

        expect($stdout).to have_received(:puts).with(version_pattern)
      end

      it 'prints version for -v' do
        cli.run(['-v'])

        expect($stdout).to have_received(:puts).with(version_pattern)
      end

      it 'prints version for --version' do
        cli.run(['--version'])

        expect($stdout).to have_received(:puts).with(version_pattern)
      end
    end

    context 'with help command' do
      it 'prints help for help' do
        cli.run(['help'])

        expect($stdout).to have_received(:puts).with(/Usage: rubocop-claude/)
      end

      it 'prints help for -h' do
        cli.run(['-h'])

        expect($stdout).to have_received(:puts).with(/Usage: rubocop-claude/)
      end

      it 'prints help for --help' do
        cli.run(['--help'])

        expect($stdout).to have_received(:puts).with(/Usage: rubocop-claude/)
      end

      it 'prints help for no arguments' do
        cli.run([])

        expect($stdout).to have_received(:puts).with(/Usage: rubocop-claude/)
      end
    end

    context 'with unknown command' do
      it 'exits with error' do
        allow(cli).to receive(:warn)

        expect { cli.run(['unknown']) }.to raise_error(SystemExit)
      end

      it 'prints warning message' do
        allow(cli).to receive(:warn)
        allow(cli).to receive(:exit)

        cli.run(['unknown'])

        expect(cli).to have_received(:warn).with(/Unknown command: unknown/)
      end
    end
  end
end
