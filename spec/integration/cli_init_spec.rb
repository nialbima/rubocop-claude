# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

RSpec.describe 'CLI init command', :integration do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  def run_init(inputs)
    Dir.chdir(tmpdir) do
      # Simulate stdin inputs
      input_io = StringIO.new(inputs.join("\n") + "\n")
      allow($stdin).to receive(:gets) { input_io.gets }

      # Capture output
      output = StringIO.new
      allow($stdout).to receive(:puts) { |*args| output.puts(*args) }
      allow($stdout).to receive(:print) { |*args| output.print(*args) }

      require 'rubocop_claude/cli'
      RubocopClaude::InitWizard.new.run

      output.string
    end
  end

  describe 'creates expected files' do
    it 'creates .claude directory' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      run_init(%w[n s g n 2 n])

      expect(Dir.exist?(File.join(tmpdir, '.claude'))).to be true
    end

    it 'creates linting.md' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      run_init(%w[n s g n 2 n])

      linting_path = File.join(tmpdir, '.claude', 'linting.md')
      expect(File.exist?(linting_path)).to be true
      expect(File.read(linting_path)).to include('Linting')
    end

    it 'creates cop guides directory' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      run_init(%w[n s g n 2 n])

      cops_dir = File.join(tmpdir, '.claude', 'cops')
      expect(Dir.exist?(cops_dir)).to be true
      expect(Dir.glob(File.join(cops_dir, '*.md')).size).to be > 0
    end

    it 'creates .standard.yml when StandardRB selected' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      run_init(%w[n s g n 2 n])

      standard_yml = File.join(tmpdir, '.standard.yml')
      expect(File.exist?(standard_yml)).to be true

      content = YAML.load_file(standard_yml)
      expect(content['plugins']).to include('rubocop-claude')
    end

    it 'creates .rubocop.yml when RuboCop selected' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      run_init(%w[n r g n 2 n])

      rubocop_yml = File.join(tmpdir, '.rubocop.yml')
      expect(File.exist?(rubocop_yml)).to be true

      content = YAML.load_file(rubocop_yml)
      expect(content['require']).to include('rubocop-claude')
    end

    it 'creates .rubocop_claude.yml with preferences' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      # Select modifier style and single-line commented code
      run_init(%w[n s m n 1 n])

      config_path = File.join(tmpdir, '.rubocop_claude.yml')
      expect(File.exist?(config_path)).to be true

      content = YAML.load_file(config_path)
      expect(content['Claude/ExplicitVisibility']['EnforcedStyle']).to eq('modifier')
      expect(content['Claude/NoCommentedCode']['MinLines']).to eq(1)
    end
  end

  describe 'hooks installation' do
    it 'creates hooks when enabled' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      # Say yes to hooks (last prompt)
      run_init(%w[n s g n 2 y])

      hook_script = File.join(tmpdir, '.claude', 'hooks', 'ruby-lint.sh')
      expect(File.exist?(hook_script)).to be true
      expect(File.executable?(hook_script)).to be true

      settings = File.join(tmpdir, '.claude', 'settings.local.json')
      expect(File.exist?(settings)).to be true

      content = JSON.parse(File.read(settings))
      expect(content['hooks']['PostToolUse']).to be_an(Array)
    end

    it 'does not create hooks when disabled' do
      File.write(File.join(tmpdir, 'Gemfile'), "source 'https://rubygems.org'")

      # Say no to hooks (last prompt)
      run_init(%w[n s g n 2 n])

      hook_script = File.join(tmpdir, '.claude', 'hooks', 'ruby-lint.sh')
      expect(File.exist?(hook_script)).to be false
    end
  end

  describe 'Gemfile handling' do
    it 'adds gem to development group when present' do
      gemfile_content = <<~GEMFILE
        source 'https://rubygems.org'

        group :development do
          gem 'pry'
        end
      GEMFILE
      File.write(File.join(tmpdir, 'Gemfile'), gemfile_content)

      run_init(%w[y s g n 2 n])

      updated = File.read(File.join(tmpdir, 'Gemfile'))
      expect(updated).to include("gem 'rubocop-claude', require: false")
    end

    it 'skips Gemfile modification when declined' do
      gemfile_content = "source 'https://rubygems.org'"
      File.write(File.join(tmpdir, 'Gemfile'), gemfile_content)

      run_init(%w[n s g n 2 n])

      updated = File.read(File.join(tmpdir, 'Gemfile'))
      expect(updated).not_to include('rubocop-claude')
    end
  end
end
