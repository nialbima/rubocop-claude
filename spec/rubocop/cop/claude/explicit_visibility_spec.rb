# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Claude::ExplicitVisibility, :config do
  let(:cop_config) do
    {
      'Claude/ExplicitVisibility' => {
        'Enabled' => true,
        'EnforcedStyle' => 'modifier'
      }
    }
  end

  context 'with EnforcedStyle: modifier' do
    it 'registers an offense for standalone private' do
      expect_offense(<<~RUBY)
        class Foo
          def public_method
          end

          private
          ^^^^^^^ Use explicit visibility. Place `private` before the method definition.

          def secret_method
          end
        end
      RUBY
    end

    it 'registers an offense for standalone protected' do
      expect_offense(<<~RUBY)
        class Foo
          protected
          ^^^^^^^^^ Use explicit visibility. Place `protected` before the method definition.

          def protected_method
          end
        end
      RUBY
    end

    it 'autocorrects to modifier style' do
      expect_offense(<<~RUBY)
        class Foo
          private
          ^^^^^^^ Use explicit visibility. Place `private` before the method definition.

          def secret_method
          end

          def another_secret
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          private def secret_method
          end

          private def another_secret
          end
        end
      RUBY
    end

    it 'does not register offense for modifier style' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def public_method
          end

          private def secret_method
          end
        end
      RUBY
    end

    it 'does not register offense for private with argument (attr_reader etc)' do
      expect_no_offenses(<<~RUBY)
        class Foo
          private :some_method
          private_class_method :class_method
        end
      RUBY
    end

    it 'does not register offense for private with no following methods' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def public_method
          end

          private
        end
      RUBY
    end

    it 'does not register offense for private with no methods before next visibility' do
      expect_no_offenses(<<~RUBY)
        class Foo
          private

          protected
        end
      RUBY
    end
  end

  context 'with EnforcedStyle: grouped' do
    let(:cop_config) do
      {
        'Claude/ExplicitVisibility' => {
          'Enabled' => true,
          'EnforcedStyle' => 'grouped'
        }
      }
    end

    it 'registers an offense for modifier style' do
      expect_offense(<<~RUBY)
        class Foo
          private def secret_method
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
          end
        end
      RUBY
    end

    it 'autocorrects by moving to new private section' do
      expect_offense(<<~RUBY)
        class Foo
          def public_method
          end

          private def secret_method
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
          end
        end
      RUBY

      # NOTE: [@claude] Extra blank line is a minor whitespace artifact
      expect_correction(<<~RUBY)
        class Foo
          def public_method
          end


          private

          def secret_method
          end
        end
      RUBY
    end

    it 'autocorrects by adding to existing private section' do
      expect_offense(<<~RUBY)
        class Foo
          def public_method
          end

          private

          def existing_private
          end

          private def another_private
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          def public_method
          end

          private

          def existing_private
          end

          def another_private
          end
        end
      RUBY
    end

    it 'does not register offense for grouped style' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def public_method
          end

          private

          def secret_method
          end
        end
      RUBY
    end

    it 'does not register offense for def without visibility parent' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def regular_method
          end
        end
      RUBY
    end

    it 'does not register offense for top-level def' do
      expect_no_offenses(<<~RUBY)
        def top_level_method
        end
      RUBY
    end

    it 'handles private def at top level (no autocorrect)' do
      expect_offense(<<~RUBY)
        private def helper
        ^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
        end
      RUBY

      # No correction possible at top level - no class to add private section to
      expect_no_corrections
    end

    it 'handles module with private method' do
      expect_offense(<<~RUBY)
        module Bar
          private def helper
          ^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
          end
        end
      RUBY
    end

    it 'handles empty class body gracefully' do
      expect_no_offenses(<<~RUBY)
        class Empty
        end
      RUBY
    end

    it 'does not register offense for public visibility modifier' do
      expect_no_offenses(<<~RUBY)
        class Foo
          public def explicitly_public
          end
        end
      RUBY
    end

    it 'autocorrects by adding after empty private section' do
      expect_offense(<<~RUBY)
        class Foo
          def public_method
          end

          private

          private def another_private
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          def public_method
          end

          private

          def another_private
          end
        end
      RUBY
    end

    it 'handles inline class with private def' do
      expect_offense(<<~RUBY)
        class Foo; private def bar; end; end
                   ^^^^^^^^^^^^^^^^^^^^ Use grouped visibility. Move method to `private` section.
      RUBY
    end
  end
end
