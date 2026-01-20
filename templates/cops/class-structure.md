# Layout/ClassStructure

**What it catches:** Class/module contents in wrong order.

**Why it matters:** Consistent ordering makes code easier to navigate.

## Expected Order

1. `include`, `extend`, `prepend`
2. Constants
3. Class methods (`def self.foo`)
4. `initialize`
5. Public instance methods
6. Protected methods
7. Private methods

## How to Fix

```ruby
# BAD
class User
  def greet
    "Hello"
  end

  include Comparable

  ROLE = "admin"

  def initialize(name)
    @name = name
  end
end

# GOOD
class User
  include Comparable

  ROLE = "admin"

  def initialize(name)
    @name = name
  end

  def greet
    "Hello"
  end
end
```

## Autocorrection

**This cop autocorrects** - it will reorder methods automatically.

## Decision Criteria

- Let the autocorrect handle it
- If it produces odd results, review manually and adjust
