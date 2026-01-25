# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Claude::NoHardcodedLineNumbers, :config do
  describe 'comment detection' do
    context 'when comments contain line number references' do
      it 'registers an offense for "line 42"' do
        expect_offense(<<~RUBY)
          # see line 42 for details
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for "Line 42" (case insensitive)' do
        expect_offense(<<~RUBY)
          # See Line 42 for details
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `Line 42`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for "at line 15"' do
        expect_offense(<<~RUBY)
          # at line 15, we handle errors
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 15`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for "on line 20"' do
        expect_offense(<<~RUBY)
          # on line 20, the validation happens
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 20`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for "L42" (GitHub style)' do
        expect_offense(<<~RUBY)
          # Check L42 for the fix
          ^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `L42`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for "foo.rb:123"' do
        expect_offense(<<~RUBY)
          # Error defined at foo.rb:123
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `.rb:123`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for ERB files' do
        expect_offense(<<~RUBY)
          # See app/views/users/show.erb:42
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `.erb:42`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'registers an offense for rake files' do
        expect_offense(<<~RUBY)
          # Defined in lib/tasks/deploy.rake:15
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `.rake:15`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end
    end

    context 'when comments contain non-line-number patterns' do
      it 'ignores "Ruby 3.1"' do
        expect_no_offenses(<<~RUBY)
          # Ruby 3.1 introduced pattern matching
          def foo; end
        RUBY
      end

      it 'ignores "version 2"' do
        expect_no_offenses(<<~RUBY)
          # version 2 of the API
          def foo; end
        RUBY
      end

      it 'ignores "port 8080"' do
        expect_no_offenses(<<~RUBY)
          # Listen on port 8080
          def foo; end
        RUBY
      end

      it 'ignores semver strings' do
        expect_no_offenses(<<~RUBY)
          # Requires 1.2.3 or higher
          def foo; end
        RUBY
      end

      it 'ignores "v1.2.3"' do
        expect_no_offenses(<<~RUBY)
          # Since v1.2.3
          def foo; end
        RUBY
      end

      it 'ignores "pid: 1234"' do
        expect_no_offenses(<<~RUBY)
          # Process pid: 1234
          def foo; end
        RUBY
      end

      it 'ignores "id: 42"' do
        expect_no_offenses(<<~RUBY)
          # Record id: 42
          def foo; end
        RUBY
      end

      it 'ignores time durations' do
        expect_no_offenses(<<~RUBY)
          # Timeout after 30 seconds
          # Takes 100ms to complete
          def foo; end
        RUBY
      end

      it 'ignores byte sizes' do
        expect_no_offenses(<<~RUBY)
          # Buffer is 100 bytes
          # Max 5mb upload
          def foo; end
        RUBY
      end

      it 'ignores percentages' do
        expect_no_offenses(<<~RUBY)
          # 50% complete
          def foo; end
        RUBY
      end

      it 'ignores dollar amounts' do
        expect_no_offenses(<<~RUBY)
          # Costs $42
          def foo; end
        RUBY
      end

      it 'ignores issue references' do
        expect_no_offenses(<<~RUBY)
          # Fix for #42
          def foo; end
        RUBY
      end

      it 'ignores regular comments without line references' do
        expect_no_offenses(<<~RUBY)
          # This is a regular comment
          def foo; end
        RUBY
      end
    end
  end

  describe 'string detection' do
    context 'when strings contain line number references' do
      it 'registers an offense for "error at line 42"' do
        expect_offense(<<~RUBY)
          raise "error at line 42"
                ^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
        RUBY
      end

      it 'registers an offense for file:line format in strings' do
        expect_offense(<<~RUBY)
          message = "error in foo.rb:55"
                    ^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `.rb:55`. Line numbers shift when code changes.
        RUBY
      end

      it 'registers an offense in test assertions' do
        expect_offense(<<~RUBY)
          expect(error.message).to include("line 10")
                                           ^^^^^^^^^ Avoid hardcoded line number `line 10`. Line numbers shift when code changes.
        RUBY
      end
    end

    context 'when strings contain non-line-number patterns' do
      it 'ignores version strings' do
        expect_no_offenses(<<~RUBY)
          version = "1.2.3"
        RUBY
      end

      it 'ignores URLs with port numbers' do
        expect_no_offenses(<<~RUBY)
          url = "http://localhost:8080"
        RUBY
      end

      it 'ignores regular strings' do
        expect_no_offenses(<<~RUBY)
          message = "Hello, world!"
        RUBY
      end
    end
  end

  describe 'configuration options' do
    context 'when CheckComments is false' do
      let(:cop_config) do
        {
          'Claude/NoHardcodedLineNumbers' => {
            'Enabled' => true,
            'CheckComments' => false,
            'CheckStrings' => true,
            'MinLineNumber' => 1
          }
        }
      end

      it 'does not flag comments' do
        expect_no_offenses(<<~RUBY)
          # see line 42 for details
          def foo; end
        RUBY
      end

      it 'still flags strings' do
        expect_offense(<<~RUBY)
          raise "error at line 42"
                ^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
        RUBY
      end
    end

    context 'when CheckStrings is false' do
      let(:cop_config) do
        {
          'Claude/NoHardcodedLineNumbers' => {
            'Enabled' => true,
            'CheckComments' => true,
            'CheckStrings' => false,
            'MinLineNumber' => 1
          }
        }
      end

      it 'still flags comments' do
        expect_offense(<<~RUBY)
          # see line 42 for details
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end

      it 'does not flag strings' do
        expect_no_offenses(<<~RUBY)
          raise "error at line 42"
        RUBY
      end

      it 'does not flag interpolated strings' do
        expect_no_offenses(<<~'RUBY')
          raise "error at line 42 in #{file}"
        RUBY
      end
    end

    context 'when MinLineNumber is set' do
      let(:cop_config) do
        {
          'Claude/NoHardcodedLineNumbers' => {
            'Enabled' => true,
            'CheckComments' => true,
            'CheckStrings' => true,
            'MinLineNumber' => 10
          }
        }
      end

      it 'ignores line numbers below the minimum' do
        expect_no_offenses(<<~RUBY)
          # see line 5 for details
          def foo; end
        RUBY
      end

      it 'flags line numbers at or above the minimum' do
        expect_offense(<<~RUBY)
          # see line 10 for details
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 10`. Line numbers shift when code changes.
          def foo; end
        RUBY
      end
    end
  end

  describe 'edge cases' do
    it 'reports only the first offense per node' do
      expect_offense(<<~RUBY)
        # see line 42 and line 55
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
        def foo; end
      RUBY
    end

    it 'handles interpolated strings' do
      expect_offense(<<~'RUBY')
        message = "error at line 42 in #{file}"
                   ^^^^^^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
      RUBY
    end

    it 'ignores heredocs' do
      expect_no_offenses(<<~RUBY)
        doc = <<~TEXT
          See line 42 for details
          Error at foo.rb:123
        TEXT
      RUBY
    end

    it 'ignores heredocs with interpolation' do
      expect_no_offenses(<<~'RUBY')
        doc = <<~TEXT
          See line 42 for #{details}
        TEXT
      RUBY
    end

    it 'flags interpolated strings not in heredocs' do
      expect_offense(<<~'RUBY')
        msg = "see line 42 at #{path}"
               ^^^^^^^^^^^^^^^ Avoid hardcoded line number `line 42`. Line numbers shift when code changes.
      RUBY
    end

    it 'handles empty strings' do
      expect_no_offenses(<<~RUBY)
        message = ""
      RUBY
    end

    it 'handles strings with only whitespace' do
      expect_no_offenses(<<~RUBY)
        message = "   "
      RUBY
    end
  end
end
