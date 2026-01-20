# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Claude::TaggedComments, :config do
  let(:cop_config) do
    {
      "Claude/TaggedComments" => {
        "Enabled" => true,
        "Keywords" => %w[TODO FIXME NOTE HACK OPTIMIZE REVIEW]
      }
    }
  end

  context "when comments lack attribution" do
    it "registers an offense for unattributed TODO" do
      expect_offense(<<~RUBY)
        # TODO: Fix this later
        ^^^^^^^^^^^^^^^^^^^^^^ Comments need attribution. Use format: # TODO [@handle]: description
        def foo; end
      RUBY
    end

    it "registers an offense for unattributed FIXME" do
      expect_offense(<<~RUBY)
        # FIXME: Handle edge case
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Comments need attribution. Use format: # FIXME [@handle]: description
        def foo; end
      RUBY
    end

    it "registers an offense for unattributed NOTE" do
      expect_offense(<<~RUBY)
        # NOTE: This is important
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Comments need attribution. Use format: # NOTE [@handle]: description
        def foo; end
      RUBY
    end

    it "registers an offense without colon" do
      expect_offense(<<~RUBY)
        # TODO Fix this
        ^^^^^^^^^^^^^^^ Comments need attribution. Use format: # TODO [@handle]: description
        def foo; end
      RUBY
    end

    it "registers an offense for lowercase keywords" do
      expect_offense(<<~RUBY)
        # todo: fix this
        ^^^^^^^^^^^^^^^^ Comments need attribution. Use format: # TODO [@handle]: description
        def foo; end
      RUBY
    end
  end

  context "when comments have attribution" do
    it "accepts [@handle] format" do
      expect_no_offenses(<<~RUBY)
        # TODO [@nabm]: Fix this later
        def foo; end
      RUBY
    end

    it "accepts [Name - @handle] format" do
      expect_no_offenses(<<~RUBY)
        # FIXME [Nick - @nabm]: Handle edge case
        def foo; end
      RUBY
    end

    it "accepts attribution anywhere in comment" do
      expect_no_offenses(<<~RUBY)
        # TODO: Fix this later [@nabm]
        def foo; end
      RUBY
    end
  end

  context "when not a tagged comment" do
    it "ignores regular comments" do
      expect_no_offenses(<<~RUBY)
        # This is a regular comment
        def foo; end
      RUBY
    end

    it "ignores comments that mention TODO in prose" do
      expect_no_offenses(<<~RUBY)
        # This relates to the TODO list
        def foo; end
      RUBY
    end
  end
end
