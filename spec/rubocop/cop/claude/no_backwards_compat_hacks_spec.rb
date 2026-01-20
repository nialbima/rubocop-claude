# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Claude::NoBackwardsCompatHacks, :config do
  let(:cop_config) do
    {
      'Claude/NoBackwardsCompatHacks' => {
        'Enabled' => true
      }
    }
  end

  context 'with underscore-prefixed variables (CheckUnderscoreAssignments: false, default)' do
    it 'does not register offense by default' do
      expect_no_offenses(<<~RUBY)
        _old_value = previous_calculation
        _foo = bar
      RUBY
    end
  end

  context 'with underscore-prefixed variables (CheckUnderscoreAssignments: true)' do
    let(:cop_config) do
      {
        'Claude/NoBackwardsCompatHacks' => {
          'Enabled' => true,
          'CheckUnderscoreAssignments' => true
        }
      }
    end

    it 'registers an offense for _unused assignments' do
      expect_offense(<<~RUBY)
        _old_value = previous_calculation
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete dead code. Don't use underscore prefix to preserve unused values.
      RUBY
    end

    it 'registers an offense for _unused with short names' do
      expect_offense(<<~RUBY)
        _foo = bar
        ^^^^^^^^^^ Delete dead code. Don't use underscore prefix to preserve unused values.
      RUBY
    end

    it 'does not register offense for single underscore in block' do
      expect_no_offenses(<<~RUBY)
        hash.each { |_, v| puts v }
      RUBY
    end

    it 'does not register offense for normal variable assignment' do
      expect_no_offenses(<<~RUBY)
        value = calculate_something
        name = "test"
      RUBY
    end

    it 'does not register offense for underscore-prefixed block parameter' do
      expect_no_offenses(<<~RUBY)
        items.each { |_item| process }
        data.map { |_key, value| value * 2 }
      RUBY
    end

    it 'does not register offense for underscore assignment inside block' do
      expect_no_offenses(<<~RUBY)
        items.each do |item|
          _copy = item
        end
      RUBY
    end
  end

  context 'with constant re-exports' do
    it 'registers an offense for re-export with compat comment' do
      expect_offense(<<~RUBY)
        OldName = NewName # for backwards compatibility
        ^^^^^^^^^^^^^^^^^ Delete dead code. Don't re-export removed constants for backwards compatibility.
      RUBY
    end

    it 'registers an offense for re-export with deprecated comment' do
      expect_offense(<<~RUBY)
        # deprecated alias
        LegacyClass = ModernClass
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Delete dead code. Don't re-export removed constants for backwards compatibility.
      RUBY
    end

    it 'does not register offense for normal constant assignment' do
      expect_no_offenses(<<~RUBY)
        DEFAULT_VALUE = 42
        Config = Struct.new(:name)
      RUBY
    end

    it 'does not register offense for const assignment to non-const value' do
      expect_no_offenses(<<~RUBY)
        COMPUTED = calculate_value()
        RESULT = some_method
      RUBY
    end

    it 'does not register offense for const-to-const without compat comment' do
      expect_no_offenses(<<~RUBY)
        # Convenient short name for frequently used module
        ShortName = VeryLongModuleName
      RUBY
    end
  end

  context 'with dead code marker comments' do
    it 'registers an offense for removed: comments' do
      expect_offense(<<~RUBY)
        # removed: def old_method; end
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete dead code. Don't leave removal markers in comments.
        def foo; end
      RUBY
    end

    it 'registers an offense for deprecated: comments' do
      expect_offense(<<~RUBY)
        # deprecated: use new_method instead
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete dead code. Don't leave removal markers in comments.
        def foo; end
      RUBY
    end

    it 'registers an offense for legacy: comments' do
      expect_offense(<<~RUBY)
        # legacy: keeping for backwards compat
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete dead code. Don't leave removal markers in comments.
        def foo; end
      RUBY
    end

    it 'registers an offense for backwards compatibility: comments' do
      expect_offense(<<~RUBY)
        # backwards compatibility: aliased from OldClass
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Delete dead code. Don't leave removal markers in comments.
        def foo; end
      RUBY
    end
  end
end
