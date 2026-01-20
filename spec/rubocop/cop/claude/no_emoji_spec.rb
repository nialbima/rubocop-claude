# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Claude::NoEmoji, :config do
  let(:cop_config) do
    {
      "Claude/NoEmoji" => {
        "Enabled" => true,
        "AllowedEmoji" => [],
        "AllowInStrings" => false
      }
    }
  end

  context "when emoji in strings" do
    it "registers an offense for emoji in single-quoted string" do
      expect_offense(<<~RUBY)
        puts '🎉'
             ^^^ Avoid emoji in code. Use descriptive text instead.
      RUBY
    end

    it "registers an offense for emoji in double-quoted string" do
      expect_offense(<<~RUBY)
        message = "Success! 🎉"
                  ^^^^^^^^^^^^ Avoid emoji in code. Use descriptive text instead.
      RUBY
    end

    it "registers an offense for emoji in interpolated string" do
      expect_offense(<<~RUBY)
        puts "Hello 🌍 \#{name}"
              ^^^^^^^^ Avoid emoji in code. Use descriptive text instead.
      RUBY
    end
  end

  context "when emoji in symbols" do
    it "registers an offense for emoji in symbol" do
      expect_offense(<<~RUBY)
        status = :done_✅
                 ^^^^^^^ Avoid emoji in code. Use descriptive text instead.
      RUBY
    end
  end

  context "when emoji in comments" do
    it "registers an offense for emoji in comment" do
      expect_offense(<<~RUBY)
        # TODO: Fix this bug 🐛
        ^^^^^^^^^^^^^^^^^^^^^^ Avoid emoji in code. Use descriptive text instead.
        def foo; end
      RUBY
    end
  end

  context "when no emoji" do
    it "does not register an offense for clean strings" do
      expect_no_offenses(<<~RUBY)
        puts "Success!"
        status = :completed
        # TODO: Fix this bug
      RUBY
    end
  end

  context "with AllowedEmoji configuration" do
    let(:cop_config) do
      {
        "Claude/NoEmoji" => {
          "Enabled" => true,
          "AllowedEmoji" => ["✓"],
          "AllowInStrings" => false
        }
      }
    end

    it "allows configured emoji" do
      expect_no_offenses(<<~RUBY)
        puts "Done ✓"
      RUBY
    end

    it "still catches non-allowed emoji" do
      expect_offense(<<~RUBY)
        puts "Done 🎉"
             ^^^^^^^^ Avoid emoji in code. Use descriptive text instead.
      RUBY
    end
  end

  context "with AllowInStrings configuration" do
    let(:cop_config) do
      {
        "Claude/NoEmoji" => {
          "Enabled" => true,
          "AllowedEmoji" => [],
          "AllowInStrings" => true
        }
      }
    end

    it "allows emoji in strings" do
      expect_no_offenses(<<~RUBY)
        puts "Success! 🎉"
      RUBY
    end

    it "still catches emoji in comments" do
      expect_offense(<<~RUBY)
        # Celebrate! 🎉
        ^^^^^^^^^^^^^^ Avoid emoji in code. Use descriptive text instead.
        def foo; end
      RUBY
    end

    it "still catches emoji in symbols" do
      expect_offense(<<~RUBY)
        status = :done_✅
                 ^^^^^^^ Avoid emoji in code. Use descriptive text instead.
      RUBY
    end
  end
end
