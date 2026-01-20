# Claude/MethodParameterShadowing

**What it catches:** Method parameters with the same name as instance variables used in the class.

**Why it matters:** `def update(name)` when `@name` exists creates confusion about which `name` is referenced.

## How to Fix

```ruby
# BAD
class User
  def initialize(name)
    @name = name
  end

  def update(name)  # shadows @name
    @name = name
  end
end

# GOOD
class User
  def initialize(name)
    @name = name
  end

  def update(new_name)  # clear it's the incoming value
    @name = new_name
  end
end
```

## Common Renames

| Original | Replacement |
|----------|-------------|
| `name` | `new_name`, `updated_name` |
| `value` | `new_value`, `input_value` |
| `status` | `new_status`, `updated_status` |
| `data` | `new_data`, `input_data` |

## Exception

`initialize` is exempt - it commonly uses ivar-matching names.

## Decision Criteria

- Prefix with `new_` or `updated_` depending on context
- For setters, `new_value` is idiomatic
- Ask if the rename isn't obvious
