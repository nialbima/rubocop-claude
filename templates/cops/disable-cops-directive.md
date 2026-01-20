# Style/DisableCopsWithinSourceCodeDirective

**What it catches:** `# rubocop:disable` comments inline.

**Why it matters:** Disabling cops hides problems rather than fixing them.

## How to Fix

**Don't disable the cop.** Fix the underlying issue instead.

```ruby
# BAD
# rubocop:disable Metrics/MethodLength
def very_long_method
  # ... lots of code ...
end
# rubocop:enable Metrics/MethodLength

# GOOD - refactor the method
def method_part_one
  # ...
end

def method_part_two
  # ...
end
```

## Decision Criteria

- If you genuinely can't fix the issue, **ask the human**
- Never add `# rubocop:disable` without explicit human approval
- If the cop seems wrong for this codebase, discuss with the human about configuring it globally
