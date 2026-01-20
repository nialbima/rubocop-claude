# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Claude::NoOverlyDefensiveCode, :config do
  let(:cop_config) do
    {
      "Claude/NoOverlyDefensiveCode" => {
        "Enabled" => true,
        "MaxSafeNavigationChain" => 2
      }
    }
  end

  context "with error swallowing" do
    it "registers an offense for rescue with nil body" do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue => e
        ^^^^^^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
        end
      RUBY
    end

    it "registers an offense for rescue returning nil" do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue
        ^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
          nil
        end
      RUBY
    end

    it "does not register offense for meaningful rescue" do
      expect_no_offenses(<<~RUBY)
        begin
          risky_operation
        rescue StandardError => e
          log_error(e)
          fallback_value
        end
      RUBY
    end

    it "does not register offense for rescue with return value" do
      expect_no_offenses(<<~RUBY)
        begin
          risky_operation
        rescue
          default_value
        end
      RUBY
    end
  end

  context "with excessive safe navigation" do
    it "registers an offense for 3+ chained &." do
      expect_offense(<<~RUBY)
        user&.profile&.settings&.value
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. Excessive safe navigation (3 chained `&.`) suggests uncertain data model. Use explicit nil checks or fix the source.
      RUBY
    end

    it "registers an offense for 4 chained &." do
      expect_offense(<<~RUBY)
        a&.b&.c&.d&.e
        ^^^^^^^^^^^^^ Trust internal code. Excessive safe navigation (4 chained `&.`) suggests uncertain data model. Use explicit nil checks or fix the source.
      RUBY
    end

    it "does not register offense for 2 chained &." do
      expect_no_offenses(<<~RUBY)
        user&.profile&.name
      RUBY
    end

    it "does not register offense for single &." do
      expect_no_offenses(<<~RUBY)
        user&.name
      RUBY
    end

    it "does not register offense for regular method chain" do
      expect_no_offenses(<<~RUBY)
        user.profile.settings.value
      RUBY
    end

    it "counts only consecutive &. operators" do
      expect_no_offenses(<<~RUBY)
        user.profile&.settings&.value
      RUBY
    end
  end

  context "with custom MaxSafeNavigationChain" do
    let(:cop_config) do
      {
        "Claude/NoOverlyDefensiveCode" => {
          "Enabled" => true,
          "MaxSafeNavigationChain" => 3
        }
      }
    end

    it "respects custom max" do
      expect_no_offenses(<<~RUBY)
        user&.profile&.settings&.value
      RUBY
    end

    it "still catches chains over custom max" do
      expect_offense(<<~RUBY)
        a&.b&.c&.d&.e
        ^^^^^^^^^^^^^ Trust internal code. Excessive safe navigation (4 chained `&.`) suggests uncertain data model. Use explicit nil checks or fix the source.
      RUBY
    end
  end
end
