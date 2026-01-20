# Claude/NoCommentedCode

**What it catches:** Commented-out code (even single lines by default).

**Why it matters:** Commented code is technical debt. Version control preserves history - just delete it.

**Autocorrectable:** Yes (unsafe) - deletes the commented code. Run `rubocop -A` to auto-fix.

## How to Fix

```ruby
# BAD
# def old_method
#   do_something
# end

# BAD - even single lines
# user.update!(name: "test")

# GOOD - just delete the commented code entirely
```

## The KEEP Exception

Sometimes you genuinely need to preserve commented code temporarily. Use a `KEEP` comment with attribution:

```ruby
# GOOD - explicit, attributed, time-boxed
# KEEP [@username]: Rollback path during migration, remove after 2025-06
# def legacy_method
#   old_implementation
# end

# BAD - KEEP without attribution doesn't work
# KEEP: I might need this later
# def old_method
#   do_something
# end
```

### KEEP Rules

1. **Must have attribution** - `[@handle]` format (same as TaggedComments)
2. **Must have justification** - explain why it's kept
3. **Should be time-boxed** - include a removal date when possible
4. **Only protects the immediately following block** - prose comments break the protection

## For AI Assistants

**Default behavior: delete commented code.** Don't ask "should I keep this?" - the answer is delete.

If you encounter a `# KEEP` comment with valid attribution, leave it alone. The human made an explicit decision to preserve that code.

**Never add KEEP comments yourself** unless the human explicitly asks you to preserve specific code temporarily.

## What's NOT Commented Code

These are fine and won't be flagged:

- Explanatory prose comments
- Documentation (YARD/RDoc)
- TODO/FIXME/NOTE annotations
- `@example` blocks in documentation
- RuboCop directives

## Configuration

```yaml
Claude/NoCommentedCode:
  MinLines: 1        # Flag even single lines (default)
  AllowKeep: true    # Honor KEEP comments with attribution (default)
```

Set `MinLines: 2` if single-line detection is too noisy for your codebase.
