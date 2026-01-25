# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rubocop_claude/cli'

RSpec.describe RubocopClaude::InitWizard, :integration do
  subject(:wizard) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  let!(:original_dir) { Dir.pwd }

  before do
    Dir.chdir(tmpdir)
  end

  after do
    Dir.chdir(original_dir)
    FileUtils.rm_rf(tmpdir)
  end

  def simulate_inputs(*inputs)
    input_io = StringIO.new(inputs.join("\n") + "\n")
    allow($stdin).to receive(:gets) { input_io.gets }
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  def create_gemfile
    File.write('Gemfile', "source 'https://rubygems.org'")
  end

  describe 'file creation' do
    before { create_gemfile }

    it 'creates .claude directory' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      expect(Dir.exist?('.claude')).to be true
    end

    it 'creates linting.md' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      expect(File.exist?('.claude/linting.md')).to be true
    end

    it 'creates cop guides directory with markdown files' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      expect(Dir.exist?('.claude/cops')).to be true
      expect(Dir.glob('.claude/cops/*.md').size).to be > 0
    end
  end

  describe 'linter config' do
    before { create_gemfile }

    it 'creates .standard.yml when StandardRB selected' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      expect(File.exist?('.standard.yml')).to be true
      content = YAML.load_file('.standard.yml')
      expect(content['plugins']).to include('rubocop-claude')
    end

    it 'creates .rubocop.yml when RuboCop selected' do
      simulate_inputs('n', 'r', 'g', 'n', '2', 'n')
      wizard.run

      expect(File.exist?('.rubocop.yml')).to be true
      content = YAML.load_file('.rubocop.yml')
      expect(content['require']).to include('rubocop-claude')
    end
  end

  describe 'preferences' do
    before { create_gemfile }

    it 'creates .rubocop_claude.yml with visibility style' do
      simulate_inputs('n', 's', 'm', 'n', '2', 'n')
      wizard.run

      content = YAML.load_file('.rubocop_claude.yml')
      expect(content['Claude/ExplicitVisibility']['EnforcedStyle']).to eq('modifier')
    end

    it 'creates .rubocop_claude.yml with commented code setting' do
      simulate_inputs('n', 's', 'g', 'n', '1', 'n')
      wizard.run

      content = YAML.load_file('.rubocop_claude.yml')
      expect(content['Claude/NoCommentedCode']['MinLines']).to eq(1)
    end
  end

  describe 'hooks' do
    before { create_gemfile }

    it 'creates hook files when enabled' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'y', 'r')
      wizard.run

      expect(File.exist?('.claude/hooks/ruby-lint.sh')).to be true
      expect(File.executable?('.claude/hooks/ruby-lint.sh')).to be true
      expect(File.exist?('.claude/settings.local.json')).to be true
    end

    it 'skips hooks when disabled' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      expect(File.exist?('.claude/hooks/ruby-lint.sh')).to be false
    end
  end

  describe 'Gemfile handling' do
    it 'adds gem to development group' do
      File.write('Gemfile', <<~GEMFILE)
        source 'https://rubygems.org'

        group :development do
          gem 'pry'
        end
      GEMFILE

      simulate_inputs('y', 's', 'g', 'n', '2', 'n')
      wizard.run

      content = File.read('Gemfile')
      expect(content).to include("gem 'rubocop-claude', require: false")
    end

    it 'skips when user declines' do
      create_gemfile
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      content = File.read('Gemfile')
      expect(content).not_to include('rubocop-claude')
    end
  end
end
