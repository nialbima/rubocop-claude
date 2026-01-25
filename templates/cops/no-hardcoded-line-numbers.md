# Claude/NoHardcodedLineNumbers

**What it catches:** Hardcoded line numbers in comments and strings that become stale when code shifts.

**Why it matters:** References like "see line 42" or "foo.rb:123" break silently as code evolves. Use stable references like method names, class names, or descriptive comments instead.

## How to Fix

```ruby
# BAD - line numbers shift when code changes
# see line 42 for details
# Error defined at foo.rb:123
raise "error at line 42"

# GOOD - use stable references
# see #validate_input for details
# Error defined in FooError class
raise "error in validate_input"

# GOOD - use descriptive comments
# The validation logic below handles edge cases
# See the ErrorHandler module for error definitions
```

## Patterns Detected

| Pattern | Example | Description |
|---------|---------|-------------|
| `line N` | `# see line 42` | Natural language reference |
| `lines N` | `# lines 42-50` | Plural form |
| `LN` | `# see L42` | GitHub-style reference |
| `.rb:N` | `# foo.rb:123` | Ruby file:line format |
| `.erb:N` | `# app.erb:10` | ERB file:line format |
| `.rake:N` | `# tasks.rake:5` | Rake file:line format |

## Patterns NOT Flagged

These are explicitly ignored:

- Version strings: `Ruby 3.1`, `v1.2.3`, `1.2.3`
- Port numbers: `port 8080`
- IDs: `id: 42`, `pid: 1234`
- Time durations: `30 seconds`, `100ms`
- Byte sizes: `100 bytes`, `5mb`
- Percentages: `50%`
- Dollar amounts: `$42`
- Issue references: `#42`

## Configuration

```yaml
Claude/NoHardcodedLineNumbers:
  Enabled: true
  CheckComments: true   # Check comments for line refs (default: true)
  CheckStrings: true    # Check string literals (default: true)
  MinLineNumber: 1      # Only flag line numbers >= this (default: 1)
```

## Better Alternatives

| Instead of... | Use... |
|---------------|--------|
| `# see line 42` | `# see #method_name` |
| `# foo.rb:123` | `# see FooClass#method` |
| `"error at line 42"` | `"error in validate_input"` |
| `# L42 handles this` | `# The validation block handles this` |

## Edge Cases

The cop reports only the first line number per node to avoid noisy output. Heredocs are intentionally ignored since they often contain documentation or templates where line references may be intentional.
