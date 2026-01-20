# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Claude::MethodParameterShadowing, :config do
  let(:cop_config) do
    {
      "Claude/MethodParameterShadowing" => {
        "Enabled" => true
      }
    }
  end

  context "when parameter shadows instance variable" do
    it "registers an offense for shadowing @name" do
      expect_offense(<<~RUBY)
        class User
          def initialize(name)
            @name = name
          end

          def update(name)
                     ^^^^ Parameter `name` shadows instance variable `@name`. Use a different name.
            @name = name
          end
        end
      RUBY
    end

    it "registers an offense for multiple shadowing parameters" do
      expect_offense(<<~RUBY)
        class User
          def initialize(name, email)
            @name = name
            @email = email
          end

          def update(name, email)
                     ^^^^ Parameter `name` shadows instance variable `@name`. Use a different name.
                           ^^^^^ Parameter `email` shadows instance variable `@email`. Use a different name.
            @name = name
            @email = email
          end
        end
      RUBY
    end

    it "registers an offense for keyword arguments" do
      expect_offense(<<~RUBY)
        class User
          def initialize(name:)
            @name = name
          end

          def update(name:)
                     ^^^^^ Parameter `name` shadows instance variable `@name`. Use a different name.
            @name = name
          end
        end
      RUBY
    end

    it "registers an offense for optional arguments" do
      expect_offense(<<~RUBY)
        class User
          attr_accessor :name

          def update(name = "default")
                     ^^^^^^^^^^^^^^^^ Parameter `name` shadows instance variable `@name`. Use a different name.
            @name = name
          end
        end
      RUBY
    end
  end

  context "when initialize is exempt" do
    it "does not register offense for initialize" do
      expect_no_offenses(<<~RUBY)
        class User
          def initialize(name)
            @name = name
          end
        end
      RUBY
    end
  end

  context "when parameter does not shadow" do
    it "does not register offense for different names" do
      expect_no_offenses(<<~RUBY)
        class User
          def initialize(name)
            @name = name
          end

          def update(new_name)
            @name = new_name
          end
        end
      RUBY
    end

    it "does not register offense when no ivars exist" do
      expect_no_offenses(<<~RUBY)
        class User
          def update(name)
            puts name
          end
        end
      RUBY
    end
  end

  context "in module" do
    it "registers an offense for shadowing in module" do
      expect_offense(<<~RUBY)
        module Updateable
          def setup(name)
            @name = name
          end

          def update(name)
                     ^^^^ Parameter `name` shadows instance variable `@name`. Use a different name.
            @name = name
          end
        end
      RUBY
    end
  end
end
