# Claude/NoCommentedCode

**What it catches:** Commented-out code blocks (2+ consecutive lines by default).

**Why it matters:** Commented code is technical debt. Version control preserves history - just delete it.

## How to Fix

```ruby
# BAD
# def old_method
#   do_something
#   do_something_else
# end

# BAD
# user.update!(name: "test")
# User.find(1).destroy

# GOOD - just delete the commented code entirely
```

## What's NOT Commented Code (These Are Fine)

- Explanatory comments describing what code does
- Documentation comments
- TODO/FIXME annotations
- Example usage in comments
- YARD/RDoc documentation

## Decision Criteria

- If it parses as Ruby, **delete it**
- If you think "but we might need this later" - **delete it anyway**, use git history
- **NEVER** ask "should I keep this?" - the answer is always delete
