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

    it 'skips prompt when Gemfile does not exist' do
      simulate_inputs('s', 'g', 'n', '2', 'n')
      wizard.run

      expect(File.exist?('Gemfile')).to be false
    end

    it 'skips when Gemfile already includes rubocop-claude' do
      File.write('Gemfile', "source 'https://rubygems.org'\ngem 'rubocop-claude'")
      simulate_inputs('s', 'g', 'n', '2', 'n')
      wizard.run

      content = File.read('Gemfile')
      expect(content.scan('rubocop-claude').size).to eq(1)
    end

    it 'appends to Gemfile without development group' do
      File.write('Gemfile', "source 'https://rubygems.org'\ngem 'rails'")
      simulate_inputs('y', 's', 'g', 'n', '2', 'n')
      wizard.run

      content = File.read('Gemfile')
      expect(content).to include("gem 'rubocop-claude', require: false")
    end
  end

  describe 'edge cases' do
    before { create_gemfile }

    it 'handles .claude directory already existing' do
      FileUtils.mkdir_p('.claude')
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')

      expect { wizard.run }.not_to raise_error
      expect(Dir.exist?('.claude')).to be true
    end

    it 'prompts to overwrite existing linting.md' do
      FileUtils.mkdir_p('.claude')
      File.write('.claude/linting.md', 'existing content')
      simulate_inputs('n', 's', 'g', 'n', '2', 'n', 'n')
      wizard.run

      expect(File.read('.claude/linting.md')).to eq('existing content')
    end

    it 'overwrites linting.md when user confirms' do
      FileUtils.mkdir_p('.claude')
      File.write('.claude/linting.md', 'existing content')
      simulate_inputs('n', 's', 'g', 'n', '2', 'n', 'y')
      wizard.run

      expect(File.read('.claude/linting.md')).not_to eq('existing content')
    end

    it 'merges with existing .rubocop_claude.yml' do
      File.write('.rubocop_claude.yml', YAML.dump({'Existing/Cop' => {'Enabled' => true}}))
      simulate_inputs('n', 's', 'm', 'n', '2', 'n')
      wizard.run

      content = YAML.load_file('.rubocop_claude.yml')
      expect(content['Existing/Cop']).to eq({'Enabled' => true})
      expect(content['Claude/ExplicitVisibility']).to be_a(Hash)
    end

    it 'always creates local config with default preferences' do
      simulate_inputs('n', 's', 'g', 'n', '2', 'n')
      wizard.run

      expect(File.exist?('.rubocop_claude.yml')).to be true
      content = YAML.load_file('.rubocop_claude.yml')
      expect(content['Claude/ExplicitVisibility']['EnforcedStyle']).to eq('grouped')
      expect(content['Claude/NoCommentedCode']['MinLines']).to eq(2)
    end
  end

  describe 'prompt edge cases' do
    before { create_gemfile }

    it 'handles nil input for yes/no prompt' do
      allow($stdin).to receive(:gets).and_return(nil)
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.prompt_yes?('Test?', default: true)
      expect(result).to be true
    end

    it 'handles empty input for yes/no prompt' do
      allow($stdin).to receive(:gets).and_return("\n")
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.prompt_yes?('Test?', default: false)
      expect(result).to be false
    end

    it 'handles nil input for choice prompt' do
      allow($stdin).to receive(:gets).and_return(nil)
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.prompt_choice('Test?', {'a' => 'A', 'b' => 'B'}, default: 'a')
      expect(result).to eq('a')
    end

    it 'handles empty input for choice prompt' do
      allow($stdin).to receive(:gets).and_return("\n")
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.prompt_choice('Test?', {'a' => 'A', 'b' => 'B'}, default: 'b')
      expect(result).to eq('b')
    end

    it 'handles invalid input for choice prompt' do
      allow($stdin).to receive(:gets).and_return("x\n")
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.prompt_choice('Test?', {'a' => 'A', 'b' => 'B'}, default: 'a')
      expect(result).to eq('a')
    end
  end

  describe 'load_yaml edge cases' do
    before { create_gemfile }

    it 'returns empty hash for non-existent file' do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.load_yaml('nonexistent.yml')
      expect(result).to eq({})
    end

    it 'returns empty hash for empty file' do
      File.write('empty.yml', '')
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)

      result = wizard.load_yaml('empty.yml')
      expect(result).to eq({})
    end
  end
end
