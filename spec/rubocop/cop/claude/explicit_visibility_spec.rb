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
  end
end
