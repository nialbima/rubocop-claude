# Claude/TaggedComments

**What it catches:** TODO/FIXME/NOTE/HACK comments without attribution.

**Why it matters:** Anonymous TODOs lose context. Attribution helps track ownership and provides contact for questions.

## How to Fix

```ruby
# BAD
# TODO: Refactor this method
# FIXME: Handle edge case

# GOOD
# TODO [@nabm]: Refactor this method - it's doing too much
# FIXME [Nick - @nabm]: Handle edge case where user is nil
```

## Format

`# TAG [@handle]: description` or `# TAG [Name - @handle]: description`

## Decision Criteria

- **Use your own handle/name** when adding new comments
- **When fixing existing comments** - ask the human whose attribution to use
- Don't guess - ask "Who should I attribute this TODO to?"
