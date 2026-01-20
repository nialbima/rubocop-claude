# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Claude::NoFancyUnicode, :config do
  let(:cop_config) do
    {
      'Claude/NoFancyUnicode' => {
        'Enabled' => true,
        'AllowedUnicode' => [],
        'AllowInStrings' => false,
        'AllowInComments' => false
      }
    }
  end

  context 'with emoji in strings' do
    it 'registers an offense and removes trailing space' do
      expect_offense(<<~RUBY)
        puts "Success! 🎉"
             ^^^^^^^^^^^^ Avoid fancy Unicode `🎉` (U+1F389). Use standard ASCII or add to AllowedUnicode.
      RUBY

      expect_correction(<<~RUBY)
        puts "Success!"
      RUBY
    end

    it 'registers an offense for emoji in interpolated string' do
      expect_offense(<<~'RUBY')
        puts "Hello #{name} 🎉"
                           ^^ Avoid fancy Unicode `🎉` (U+1F389). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end

  context 'with emoji in comments' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # TODO: Fix bug 🐛
        ^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `🐛` (U+1F41B). Use standard ASCII or add to AllowedUnicode.
        def fix; end
      RUBY
    end
  end

  context 'with emoji in symbols' do
    it 'registers an offense and removes trailing underscore' do
      expect_offense(<<~RUBY)
        status = :done_✅
                 ^^^^^^^ Avoid fancy Unicode `✅` (U+2705). Use standard ASCII or add to AllowedUnicode.
      RUBY

      expect_correction(<<~RUBY)
        status = :done
      RUBY
    end

    it 'registers an offense for dynamic symbols with Unicode' do
      expect_offense(<<~'RUBY')
        key = :"status_#{id}_✅"
                            ^^ Avoid fancy Unicode `✅` (U+2705). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end

  context 'with fancy typography in strings' do
    it 'registers an offense for curly quotes inside string' do
      expect_offense(<<~RUBY)
        puts "He said \u201Chello\u201D to me"
             ^^^^^^^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `\u201C` (U+201C). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end

    it 'registers an offense for em-dash in string' do
      expect_offense(<<~RUBY)
        title = "Chapter 3 \u2014 Details"
                ^^^^^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `\u2014` (U+2014). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end

  context 'with fancy typography in comments' do
    it 'registers an offense for em-dash' do
      expect_offense(<<~RUBY)
        # Section 3 \u2014 Details
        ^^^^^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `\u2014` (U+2014). Use standard ASCII or add to AllowedUnicode.
        def details; end
      RUBY
    end

    it 'registers an offense for curly quotes' do
      expect_offense(<<~RUBY)
        # He said \u201Chello\u201D
        ^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `\u201C` (U+201C). Use standard ASCII or add to AllowedUnicode.
        def greet; end
      RUBY
    end
  end

  context 'with mathematical symbols in strings' do
    it 'registers an offense for not-equal symbol' do
      expect_offense(<<~RUBY)
        puts "x \u2260 y means not equal"
             ^^^^^^^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `\u2260` (U+2260). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end

    it 'registers an offense for less-than-or-equal symbol' do
      expect_offense(<<~RUBY)
        doc = "Use \u2264 for less than or equal"
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `\u2264` (U+2264). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end

  context 'with mathematical symbols in comments' do
    it 'registers an offense for arrow' do
      expect_offense(<<~RUBY)
        # Click → to continue
        ^^^^^^^^^^^^^^^^^^^^^ Avoid fancy Unicode `→` (U+2192). Use standard ASCII or add to AllowedUnicode.
        def continue; end
      RUBY
    end
  end

  context 'with international text' do
    it 'allows Chinese characters' do
      expect_no_offenses(<<~RUBY)
        greeting = "你好世界"
      RUBY
    end

    it 'allows Japanese characters' do
      expect_no_offenses(<<~RUBY)
        message = "こんにちは"
      RUBY
    end

    it 'allows Cyrillic characters' do
      expect_no_offenses(<<~RUBY)
        text = "Привет мир"
      RUBY
    end

    it 'allows accented Latin characters' do
      expect_no_offenses(<<~RUBY)
        word = "café"
        name = "José García"
      RUBY
    end

    it 'allows Arabic characters' do
      expect_no_offenses(<<~RUBY)
        greeting = "مرحبا"
      RUBY
    end

    it 'allows Korean characters' do
      expect_no_offenses(<<~RUBY)
        hello = "안녕하세요"
      RUBY
    end
  end

  context 'with standard ASCII' do
    it 'allows all keyboard symbols' do
      expect_no_offenses(<<~RUBY)
        result = (a + b) * c / d - e % f
        valid = x != y && z <= w || q >= r
        string = "Hello, World!"
        hash = { key: 'value' }
        array = [1, 2, 3]
        regex = /foo|bar/
      RUBY
    end

    it 'allows standard quotes and operators' do
      expect_no_offenses(<<~RUBY)
        puts "double quotes"
        puts 'single quotes'
        x != y
        a <= b
        c >= d
      RUBY
    end
  end

  context 'with AllowInStrings: true' do
    let(:cop_config) do
      {
        'Claude/NoFancyUnicode' => {
          'Enabled' => true,
          'AllowInStrings' => true,
          'AllowInComments' => false
        }
      }
    end

    it 'allows fancy unicode in strings' do
      expect_no_offenses(<<~RUBY)
        puts "Success! 🎉"
        message = "Use → for next"
      RUBY
    end

    it 'allows fancy unicode in interpolated strings' do
      expect_no_offenses(<<~'RUBY')
        puts "Hello #{name} 🎉"
      RUBY
    end

    it 'still catches fancy unicode in comments' do
      expect_offense(<<~RUBY)
        # Celebration 🎉
        ^^^^^^^^^^^^^^^ Avoid fancy Unicode `🎉` (U+1F389). Use standard ASCII or add to AllowedUnicode.
        def party; end
      RUBY
    end

    it 'still catches fancy unicode in symbols' do
      expect_offense(<<~RUBY)
        status = :done_✅
                 ^^^^^^^ Avoid fancy Unicode `✅` (U+2705). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end

  context 'with AllowInComments: true' do
    let(:cop_config) do
      {
        'Claude/NoFancyUnicode' => {
          'Enabled' => true,
          'AllowInStrings' => false,
          'AllowInComments' => true
        }
      }
    end

    it 'allows fancy unicode in comments' do
      expect_no_offenses(<<~RUBY)
        # TODO: Fix bug 🐛
        # Section → Details
        def fix; end
      RUBY
    end

    it 'still catches fancy unicode in strings' do
      expect_offense(<<~RUBY)
        puts "Success! 🎉"
             ^^^^^^^^^^^^ Avoid fancy Unicode `🎉` (U+1F389). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end

  context 'with AllowedUnicode configuration' do
    let(:cop_config) do
      {
        'Claude/NoFancyUnicode' => {
          'Enabled' => true,
          'AllowedUnicode' => ['→', '←', '•']
        }
      }
    end

    it 'allows configured unicode characters in comments' do
      expect_no_offenses(<<~RUBY)
        # Click → to continue
        # Press ← to go back
        # • Item one
        def navigate; end
      RUBY
    end

    it 'allows configured unicode characters in strings' do
      expect_no_offenses(<<~'RUBY')
        puts "Click → to continue"
        list = "• First\n• Second"
      RUBY
    end

    it 'still catches non-allowed unicode' do
      expect_offense(<<~RUBY)
        puts "Success! 🎉"
             ^^^^^^^^^^^^ Avoid fancy Unicode `🎉` (U+1F389). Use standard ASCII or add to AllowedUnicode.
      RUBY
    end
  end
end
