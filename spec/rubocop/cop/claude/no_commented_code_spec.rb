# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Claude::NoCommentedCode, :config do
  let(:cop_config) do
    {
      'Claude/NoCommentedCode' => {
        'Enabled' => true,
        'MinLines' => 2
      }
    }
  end

  context 'with multi-line commented code' do
    it 'registers an offense and autocorrects commented method definition' do
      expect_offense(<<~RUBY)
        def before; end
        # def old_method
        ^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        #   do_something
        # end
        def after; end
      RUBY

      expect_correction(<<~RUBY)
        def before; end
        def after; end
      RUBY
    end

    it 'registers an offense and autocorrects commented method calls' do
      expect_offense(<<~RUBY)
        def before; end
        # user.update!(name: "test")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        # User.find(1).destroy
        def after; end
      RUBY

      expect_correction(<<~RUBY)
        def before; end
        def after; end
      RUBY
    end

    it 'registers an offense and autocorrects commented assignments' do
      expect_offense(<<~RUBY)
        def before; end
        # @name = params[:name]
        ^^^^^^^^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        # value = calculate_total
        def after; end
      RUBY

      expect_correction(<<~RUBY)
        def before; end
        def after; end
      RUBY
    end

    it 'registers an offense for commented code at end of file' do
      expect_offense(<<~RUBY)
        def foo; end
        # def old_method
        ^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        #   do_something
        # end
      RUBY

      expect_correction(<<~RUBY)
        def foo; end
      RUBY
    end
  end

  context 'with single-line commented code and MinLines: 2' do
    it 'does not register an offense for single line' do
      expect_no_offenses(<<~RUBY)
        # user.update!(name: "test")
        def foo; end
      RUBY
    end
  end

  context 'with MinLines: 1' do
    let(:cop_config) do
      {
        'Claude/NoCommentedCode' => {
          'Enabled' => true,
          'MinLines' => 1
        }
      }
    end

    it 'registers an offense for single line of commented code' do
      expect_offense(<<~RUBY)
        # user.update!(name: "test")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        def foo; end
      RUBY
    end
  end

  context 'with regular comments' do
    it 'does not register an offense for TODO comments' do
      expect_no_offenses(<<~RUBY)
        # TODO: Refactor this method
        # FIXME: Handle edge case
        def foo; end
      RUBY
    end

    it 'does not register an offense for prose comments' do
      expect_no_offenses(<<~RUBY)
        # This method handles user authentication
        # and returns a session token
        def foo; end
      RUBY
    end

    it 'does not register an offense for documentation' do
      expect_no_offenses(<<~RUBY)
        # @param name [String] the user's name
        # @return [User] the created user
        def foo; end
      RUBY
    end

    it 'does not register an offense for rubocop directives' do
      expect_no_offenses(<<~RUBY)
        # rubocop:disable Style/FrozenStringLiteral
        # rubocop:enable Style/FrozenStringLiteral
        def foo; end
      RUBY
    end
  end

  context 'with inline comments' do
    it 'ignores inline comments that look like code' do
      expect_no_offenses(<<~RUBY)
        foo = bar # user.save
        baz = qux # @value = 1
      RUBY
    end
  end

  context 'with YARD @example blocks' do
    it 'does not register an offense for code in @example' do
      expect_no_offenses(<<~RUBY)
        # @example Usage
        #   user = User.new(name: "test")
        #   user.save!
        #   user.reload
        def create_user; end
      RUBY
    end

    it 'does not register an offense for multi-line @example with method calls' do
      expect_no_offenses(<<~RUBY)
        # Provides context for projects.
        #
        # @example
        #   ctx = ProjectContext.new("/path/to/project")
        #   ctx.has_file?("Gemfile")  # => true
        #   ctx.has_file_matching_pattern?("**/*.rb")
        #
        class ProjectContext; end
      RUBY
    end

    it 'does not register an offense for @example with class definition' do
      expect_no_offenses(<<~RUBY)
        # @example Implementing an analyzer
        #   class MyAnalyzer < Base
        #     def analyze
        #       findings = []
        #       findings << build_finding(type: :dead_method)
        #       findings
        #     end
        #   end
        class Base; end
      RUBY
    end

    it 'still catches commented code after @example block ends' do
      expect_offense(<<~RUBY)
        # @example
        #   user.save!
        #
        # Regular comment here
        # user.destroy!
        ^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        # User.delete_all
        def foo; end
      RUBY
    end
  end

  context 'with KEEP comments' do
    it 'allows commented code preceded by KEEP with attribution' do
      expect_no_offenses(<<~RUBY)
        # KEEP [@username]: Rollback path during migration, remove after 2025-06
        # def legacy_method
        #   old_implementation
        # end
        def new_method; end
      RUBY
    end

    it 'allows KEEP with name and handle' do
      expect_no_offenses(<<~RUBY)
        # KEEP [Alice - @alice]: Needed for backwards compat until v3
        # OldClass = NewClass
        def foo; end
      RUBY
    end

    it 'still flags commented code when KEEP lacks attribution' do
      expect_offense(<<~RUBY)
        # KEEP: I might need this later
        # def old_method
        ^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        #   do_something
        # end
        def foo; end
      RUBY
    end

    it 'still flags commented code when KEEP has no handle' do
      expect_offense(<<~RUBY)
        # KEEP [username]: Missing @ symbol
        # def old_method
        ^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        #   do_something
        # end
        def foo; end
      RUBY
    end

    it 'only protects the immediately following block' do
      expect_offense(<<~RUBY)
        # KEEP [@username]: First block is protected
        # def first_method
        # end
        #
        # This prose breaks the KEEP protection
        # def second_method
        ^^^^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        # end
        def foo; end
      RUBY
    end
  end

  context 'with AllowKeep: false' do
    let(:cop_config) do
      {
        'Claude/NoCommentedCode' => {
          'Enabled' => true,
          'MinLines' => 2,
          'AllowKeep' => false
        }
      }
    end

    it 'flags commented code even with KEEP attribution' do
      expect_offense(<<~RUBY)
        # KEEP [@username]: This won't help when AllowKeep is false
        # def old_method
        ^^^^^^^^^^^^^^^^ Delete commented-out code instead of leaving it. Version control preserves history.
        #   do_something
        # end
        def foo; end
      RUBY
    end
  end
end
