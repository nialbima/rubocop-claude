# Claude/NoOverlyDefensiveCode

**What it catches:**
1. `rescue => e; nil` or `rescue; nil` (swallowing errors)
2. 3+ chained `&.` operators on internal objects

**Why it matters:** Defensive code hides bugs and indicates distrust of the codebase. Internal code should be trusted; errors should propagate.

## How to Fix - Error Swallowing

```ruby
# BAD
result = begin
  risky_operation
rescue => e
  nil
end

# BAD
value = dangerous_call rescue nil

# GOOD - let errors propagate
result = risky_operation

# GOOD - if you must rescue, handle meaningfully
result = begin
  risky_operation
rescue SpecificError => e
  Rails.logger.error("Operation failed: #{e.message}")
  default_value
end
```

## How to Fix - Excessive Safe Navigation

```ruby
# BAD - uncertain data model
user&.profile&.settings&.notifications&.enabled

# GOOD - trust your data model
user.profile.settings.notifications.enabled

# GOOD - explicit nil check if needed
return unless user
user.profile.settings.notifications.enabled

# GOOD - if nil is genuinely possible at system boundary
user&.profile&.settings  # Only 2 levels - acceptable
```

## Decision Criteria

- `rescue nil` is almost always wrong - ask "what error are we hiding?"
- More than 2 chained `&.` suggests uncertain data model - fix the source
- At system boundaries (external API responses), some `&.` is acceptable
