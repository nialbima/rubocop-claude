# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Claude::MysteryRegex, :config do
  let(:cop_config) do
    {
      "Claude/MysteryRegex" => {
        "Enabled" => true,
        "MaxLength" => 25
      }
    }
  end

  context "when regex exceeds max length" do
    it "registers an offense for long inline regex" do
      expect_offense(<<~RUBY)
        text.match?(/\\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\\z/)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Extract long regex to a named constant. Complex patterns deserve descriptive names.
      RUBY
    end

    it "registers an offense for long regex in condition" do
      expect_offense(<<~RUBY)
        if value =~ /^https?:\\/\\/[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Extract long regex to a named constant. Complex patterns deserve descriptive names.
          process(value)
        end
      RUBY
    end
  end

  context "when regex is within max length" do
    it "does not register an offense for short regex" do
      expect_no_offenses(<<~RUBY)
        text.match?(/\\A\\d+\\z/)
      RUBY
    end

    it "does not register an offense for regex at exactly max length" do
      # 25 characters exactly
      expect_no_offenses(<<~RUBY)
        text.match?(/\\A[a-z]{10,20}[0-9]+\\z/)
      RUBY
    end
  end

  context "when regex is assigned to constant" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        EMAIL_PATTERN = /\\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\\z/
      RUBY
    end

    it "does not register an offense for constant with comment" do
      expect_no_offenses(<<~RUBY)
        # Matches valid email addresses per RFC 5322 simplified
        EMAIL_PATTERN = /\\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\\z/
      RUBY
    end
  end

  context "with custom MaxLength" do
    let(:cop_config) do
      {
        "Claude/MysteryRegex" => {
          "Enabled" => true,
          "MaxLength" => 10
        }
      }
    end

    it "respects custom max length" do
      expect_offense(<<~RUBY)
        text.match?(/[a-zA-Z]{5,10}/)
                    ^^^^^^^^^^^^^^^^ Extract long regex to a named constant. Complex patterns deserve descriptive names.
      RUBY
    end

    it "allows regex within custom max" do
      expect_no_offenses(<<~RUBY)
        text.match?(/\\A\\d+\\z/)
      RUBY
    end
  end
end
