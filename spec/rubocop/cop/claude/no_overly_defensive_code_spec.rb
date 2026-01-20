# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Claude::NoOverlyDefensiveCode, :config do
  let(:cop_config) do
    {
      'Claude/NoOverlyDefensiveCode' => {
        'Enabled' => true,
        'MaxSafeNavigationChain' => 1
      }
    }
  end

  context 'with error swallowing' do
    it 'registers an offense for rescue with nil body' do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue => e
        ^^^^^^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
        end
      RUBY
    end

    it 'registers an offense for rescue returning nil' do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue
        ^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
          nil
        end
      RUBY
    end

    it 'registers an offense for inline rescue nil' do
      expect_offense(<<~RUBY)
        result = dangerous_call rescue nil
                                ^^^^^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
      RUBY
    end

    it 'registers an offense for rescue with empty return' do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue
        ^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
          return
        end
      RUBY
    end

    it 'registers an offense for rescue with return nil' do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue
        ^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
          return nil
        end
      RUBY
    end

    it 'does not register offense for meaningful rescue' do
      expect_no_offenses(<<~RUBY)
        begin
          risky_operation
        rescue StandardError => e
          log_error(e)
          fallback_value
        end
      RUBY
    end

    it 'does not register offense for rescue with return value' do
      expect_no_offenses(<<~RUBY)
        begin
          risky_operation
        rescue
          default_value
        end
      RUBY
    end

    it 'does not register offense for rescue with return and value' do
      expect_no_offenses(<<~RUBY)
        begin
          risky_operation
        rescue
          return @fallback
        end
      RUBY
    end

    it 'does not register offense for specific exception with empty body' do
      expect_no_offenses(<<~RUBY)
        begin
          require "optional_gem"
        rescue LoadError
          # Optional dependency not available
        end
      RUBY
    end

    it 'does not register offense for multiple specific exceptions' do
      expect_no_offenses(<<~RUBY)
        begin
          Dir.entries(path).each { |f| process(f) }
        rescue Errno::ENOENT, Errno::EACCES
          # Skip directories we can't read
        end
      RUBY
    end

    it 'registers offense for StandardError with nil body' do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue StandardError
        ^^^^^^^^^^^^^^^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
        end
      RUBY
    end

    it 'registers offense for Exception with nil body' do
      expect_offense(<<~RUBY)
        begin
          risky_operation
        rescue Exception
        ^^^^^^^^^^^^^^^^ Trust internal code. Don't swallow errors with `rescue nil` or `rescue => e; nil`.
        end
      RUBY
    end
  end

  context 'with excessive safe navigation' do
    it 'registers an offense for 2+ chained &.' do
      expect_offense(<<~RUBY)
        user&.profile&.settings
        ^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. Excessive safe navigation (2 chained `&.`) suggests uncertain data model. Use explicit nil checks or fix the source.
      RUBY
    end

    it 'registers an offense for 3 chained &.' do
      expect_offense(<<~RUBY)
        a&.b&.c&.d
        ^^^^^^^^^^ Trust internal code. Excessive safe navigation (3 chained `&.`) suggests uncertain data model. Use explicit nil checks or fix the source.
      RUBY
    end

    it 'does not register offense for single &.' do
      expect_no_offenses(<<~RUBY)
        user&.name
      RUBY
    end

    it 'does not register offense for regular method chain' do
      expect_no_offenses(<<~RUBY)
        user.profile.settings.value
      RUBY
    end

    it 'counts only consecutive &. operators' do
      expect_no_offenses(<<~RUBY)
        user.profile&.settings
      RUBY
    end
  end

  context 'with custom MaxSafeNavigationChain' do
    let(:cop_config) do
      {
        'Claude/NoOverlyDefensiveCode' => {
          'Enabled' => true,
          'MaxSafeNavigationChain' => 2
        }
      }
    end

    it 'respects custom max' do
      expect_no_offenses(<<~RUBY)
        user&.profile&.settings
      RUBY
    end

    it 'still catches chains over custom max' do
      expect_offense(<<~RUBY)
        a&.b&.c&.d
        ^^^^^^^^^^ Trust internal code. Excessive safe navigation (3 chained `&.`) suggests uncertain data model. Use explicit nil checks or fix the source.
      RUBY
    end
  end

  context 'with defensive nil checks (a && a.foo)' do
    it 'registers an offense and autocorrects to direct call by default' do
      expect_offense(<<~RUBY)
        a && a.foo
        ^^^^^^^^^^ Trust internal code. `a && a.foo` is a defensive nil check. Use `a.foo` instead.
      RUBY

      expect_correction(<<~RUBY)
        a.foo
      RUBY
    end

    it 'registers an offense for longer variable names' do
      expect_offense(<<~RUBY)
        user && user.name
        ^^^^^^^^^^^^^^^^^ Trust internal code. `user && user.name` is a defensive nil check. Use `user.name` instead.
      RUBY

      expect_correction(<<~RUBY)
        user.name
      RUBY
    end

    it 'registers an offense for method calls with arguments' do
      expect_offense(<<~RUBY)
        obj && obj.method(arg1, arg2)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `obj && obj.method(arg1, arg2)` is a defensive nil check. Use `obj.method(arg1, arg2)` instead.
      RUBY

      expect_correction(<<~RUBY)
        obj.method(arg1, arg2)
      RUBY
    end

    it 'does not register offense for different variables' do
      expect_no_offenses(<<~RUBY)
        a && b.foo
      RUBY
    end

    it 'does not register offense for non-method right side' do
      expect_no_offenses(<<~RUBY)
        a && b
      RUBY
    end

    it 'does not register offense for literal right side' do
      expect_no_offenses(<<~RUBY)
        a && 123
        b && "string"
        c && :symbol
      RUBY
    end
  end

  context 'with defensive nil checks and AddSafeNavigator: true' do
    let(:cop_config) do
      {
        'Claude/NoOverlyDefensiveCode' => {
          'Enabled' => true,
          'MaxSafeNavigationChain' => 1,
          'AddSafeNavigator' => true
        }
      }
    end

    it 'autocorrects to safe navigation' do
      expect_offense(<<~RUBY)
        a && a.foo
        ^^^^^^^^^^ Trust internal code. `a && a.foo` is a defensive nil check. Use `a&.foo` instead.
      RUBY

      expect_correction(<<~RUBY)
        a&.foo
      RUBY
    end

    it 'autocorrects with arguments' do
      expect_offense(<<~RUBY)
        user && user.fetch(:name, "default")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `user && user.fetch(:name, "default")` is a defensive nil check. Use `user&.fetch(:name, "default")` instead.
      RUBY

      expect_correction(<<~RUBY)
        user&.fetch(:name, "default")
      RUBY
    end
  end

  context 'with nil ternary patterns (foo.nil? ? x : foo)' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        foo.nil? ? default : foo
        ^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `foo.nil? ? default : foo` is a verbose nil check. Use `foo || default` instead.
      RUBY

      expect_correction(<<~RUBY)
        foo || default
      RUBY
    end

    it 'registers an offense for blank? check' do
      expect_offense(<<~RUBY)
        value.blank? ? fallback : value
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `value.blank? ? fallback : value` is a verbose nil check. Use `value || fallback` instead.
      RUBY

      expect_correction(<<~RUBY)
        value || fallback
      RUBY
    end

    it 'does not register offense for different variables' do
      expect_no_offenses(<<~RUBY)
        foo.nil? ? default : bar
      RUBY
    end

    it 'does not register offense for non-nil? condition' do
      expect_no_offenses(<<~RUBY)
        foo.empty? ? default : foo
      RUBY
    end
  end

  context 'with inverse ternary patterns (foo ? foo : default)' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        foo ? foo : default
        ^^^^^^^^^^^^^^^^^^^ Trust internal code. `foo ? foo : default` is verbose. Use `foo || default` instead.
      RUBY

      expect_correction(<<~RUBY)
        foo || default
      RUBY
    end

    it 'handles longer variable names' do
      expect_offense(<<~RUBY)
        user_name ? user_name : "Anonymous"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `user_name ? user_name : "Anonymous"` is verbose. Use `user_name || "Anonymous"` instead.
      RUBY

      expect_correction(<<~RUBY)
        user_name || "Anonymous"
      RUBY
    end

    it 'does not register offense for different variables' do
      expect_no_offenses(<<~RUBY)
        foo ? bar : default
      RUBY
    end
  end

  context 'with presence check patterns (a.present? && a.foo)' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        user.present? && user.name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `user.present? && user.name` is a defensive presence check. Use `user.name` instead.
      RUBY

      expect_correction(<<~RUBY)
        user.name
      RUBY
    end

    it 'handles method calls with arguments' do
      expect_offense(<<~RUBY)
        obj.present? && obj.fetch(:key, default)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trust internal code. `obj.present? && obj.fetch(:key, default)` is a defensive presence check. Use `obj.fetch(:key, default)` instead.
      RUBY

      expect_correction(<<~RUBY)
        obj.fetch(:key, default)
      RUBY
    end

    it 'does not register offense for different receivers' do
      expect_no_offenses(<<~RUBY)
        a.present? && b.foo
      RUBY
    end
  end

  context 'with regular if statements (not ternary)' do
    it 'does not register offense for if-else' do
      expect_no_offenses(<<~RUBY)
        if foo.nil?
          default
        else
          foo
        end
      RUBY
    end

    it 'does not register offense for unless' do
      expect_no_offenses(<<~RUBY)
        unless foo
          default
        end
      RUBY
    end
  end
end
