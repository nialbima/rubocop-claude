# Claude/NoEmoji

**What it catches:** Emoji in strings, symbols, and comments.

**Why it matters:** Emoji reduce code professionalism, can cause encoding issues, and are typically added by AI for "friendliness" rather than necessity.

## How to Fix

```ruby
# BAD
puts "Success! 🎉"
# TODO: Fix this bug 🐛
status = :completed_✅

# GOOD
puts "Success!"
# TODO: Fix this bug
status = :completed
```

## Decision Criteria

- **Remove all emoji** - there's always a descriptive text alternative
- If you're tempted to keep one, **ask the human first**
- Don't replace emoji with ASCII art or emoticons - just remove them
