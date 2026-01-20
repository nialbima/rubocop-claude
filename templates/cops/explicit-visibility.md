# Claude/ExplicitVisibility

**What it catches:** (in grouped mode) Inline `private def foo` instead of grouped `private` sections.

**Why it matters:** Grouped visibility is the dominant Ruby convention. All private methods appear under the `private` keyword, making it easy to scan a class and see its public interface at the top.

## How to Fix

```ruby
# BAD - modifier style (inline)
class User
  def public_method
  end

  private def secret_method
  end

  private def another_secret
  end
end

# GOOD - grouped style
class User
  def public_method
  end

  private

  def secret_method
  end

  def another_secret
  end
end
```

## Configuration

```yaml
Claude/ExplicitVisibility:
  Enabled: true
  EnforcedStyle: grouped  # default - or 'modifier' for inline style
```

## For AI Assistants

**When adding private methods:**
1. Place them after the `private` keyword at the bottom of the class
2. If no `private` section exists, add one before your new method
3. Don't use `private def` inline style unless the project consistently uses it

**When you see `private def`:** The project may prefer modifier style. Check other files before "fixing" it.
