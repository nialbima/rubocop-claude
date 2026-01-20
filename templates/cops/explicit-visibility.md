# Claude/ExplicitVisibility

**What it catches:** (in modifier mode) Standalone `private`/`protected` keywords instead of inline modifiers.

**Why it matters:** `private def foo` makes visibility explicit at the point of definition. You don't have to scroll to see if a method is private.

## How to Fix

```ruby
# BAD - grouped style
class User
  def public_method
  end

  private

  def secret_method
  end

  def another_secret
  end
end

# GOOD - modifier style
class User
  def public_method
  end

  private def secret_method
  end

  private def another_secret
  end
end
```

## Autocorrection

**This cop autocorrects** - it will move the visibility keyword to each method.

## Decision Criteria

- Let the autocorrect handle it
- If the project uses grouped style consistently, configure `EnforcedStyle: grouped`
