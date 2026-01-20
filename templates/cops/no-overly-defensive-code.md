# Claude/NoOverlyDefensiveCode

**What it catches:**
1. `rescue => e; nil` or `rescue nil` - swallowing errors
2. 2+ chained `&.` operators - excessive safe navigation
3. `a && a.foo` - defensive nil check before method call
4. `a.present? && a.foo` - defensive presence check
5. `foo.nil? ? default : foo` - verbose nil ternary
6. `foo ? foo : default` - verbose identity ternary

**Why it matters:** Defensive code hides bugs and indicates distrust of the codebase. Internal code should be trusted; errors should propagate.

## The Principle

Don't code defensively against your own codebase. When you add defensive patterns, you're saying "I don't trust this code." Either:
1. Fix the code so it's trustworthy, or
2. Handle the error/nil explicitly and meaningfully

## Error Swallowing

```ruby
# BAD - swallows all errors
begin
  risky_operation
rescue => e
  nil
end

# BAD - inline form
result = dangerous_call rescue nil

# GOOD - let errors propagate
result = risky_operation

# GOOD - specific exceptions with intentional ignore
begin
  require 'optional_gem'
rescue LoadError
  # Optional dependency not available
end
```

## Excessive Safe Navigation

```ruby
# BAD - 2+ chained &. violates design principles
user&.profile&.settings

# GOOD - single &. at system boundary
user&.name

# GOOD - trust your data model
user.profile.settings.notifications
```

## Defensive Nil Checks

```ruby
# BAD - pre-safe-navigation pattern
a && a.foo
user && user.name

# BAD - presence check before method call
user.present? && user.name

# GOOD (default: AddSafeNavigator: false) - trust the code
a.foo
user.name

# ALTERNATIVE (AddSafeNavigator: true) - if you really need nil safety
a&.foo
user&.name
```

## Verbose Ternaries

```ruby
# BAD - verbose nil check
foo.nil? ? default : foo
value.blank? ? fallback : value

# BAD - verbose identity check
foo ? foo : default

# GOOD - use ||
foo || default
value || fallback
```

## For AI Assistants

**When you're about to add defensive code, stop.** Ask yourself:

1. "Why don't I trust this code?" → Fix the trust issue instead
2. "What error am I hiding?" → Let it propagate or handle it properly
3. "Why might this be nil?" → Fix the data model or handle at the boundary

**The right response to uncertainty is not defensive code.** It's:
- Understanding why the uncertainty exists
- Fixing the root cause
- Or asking the human: "This could be nil/error here - how should I handle it?"

## Configuration

```yaml
Claude/NoOverlyDefensiveCode:
  Enabled: true
  MaxSafeNavigationChain: 1   # Flag 2+ chained &. operators
  AddSafeNavigator: false     # Autocorrect `a && a.foo` to `a.foo` (fail fast)
                              # Set to true for `a&.foo` (add safe nav)
```

## Related Cops

If using `rubocop-rails`, also enable:
- `Rails/Present` - catches `a && a.present?`
- `Rails/Blank` - catches `a.blank? && a.foo`
