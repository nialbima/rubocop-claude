# Claude/NoBackwardsCompatHacks

**What it catches:** Self-documented compatibility hacks - code with comments like "for backwards compatibility" or markers like `# removed:`.

**Why it matters:** Dead code should be deleted, not preserved "helpfully."

## The Principle

When removing or replacing code, **delete it completely**. Don't:
- Leave commented tombstones (`# removed: old_method`)
- Create "compatibility shims" (`OldName = NewName`)
- Silence linters with underscore prefixes (`_unused = old_value`)
- Add wrapper methods that just delegate to new ones
- Keep empty methods "for backwards compatibility"

Version control preserves history. Callers should be updated, not shimmed.

## What This Cop Detects

This cop catches **self-documented** hacks - patterns where you've helpfully commented your intent:

```ruby
# CAUGHT - has compat comment
OldName = NewName  # for backwards compatibility

# CAUGHT - dead code marker
# removed: def old_method; end
# deprecated: use new_method instead

# NOT CAUGHT - no comment (silent hack)
OldName = NewName
```

### Detection Philosophy

We only catch ~30% of compat hacks (the self-documented ones). This is intentional.

**The goal is teaching, not comprehensive detection.**

When this cop fires, you're reading this guidance and learning the principle. Even if we can't catch every case, the teaching moments shape better habits over time.

## How to Fix

### Dead Code Markers

```ruby
# BAD
# removed: def old_method; end
# deprecated: use new_method instead
# legacy: keeping for backwards compat

# GOOD - just delete the comment entirely
```

### Constant Re-exports

```ruby
# BAD
OldClassName = NewClassName  # for backwards compatibility

# GOOD - delete the alias, update all callers
# (yes, even if there are many callers)
```

### Underscore Assignments (optional check)

```ruby
# BAD (if CheckUnderscoreAssignments: true)
_old_value = calculate_something

# GOOD - delete the line if the value isn't needed
```

## For AI Assistants

**When you're about to add a compat shim, stop.** Ask yourself:

1. "Am I preserving dead code?" → Delete it instead
2. "Will callers break?" → Update the callers
3. "There are too many callers" → Update them anyway, or ask the human
4. "What if someone needs the old behavior?" → They can use git history

**Never:**
- Add `# for backwards compatibility` comments
- Create `OldName = NewName` aliases
- Use `_unused = value` to silence linters
- Leave `# removed:` or `# deprecated:` markers
- Create wrapper methods that just delegate

**Instead:**
- Delete the old code completely
- Update all callers to use the new code
- If unsure, ask: "Should I update all callers or is there a reason to keep the old interface?"

## Configuration

```yaml
Claude/NoBackwardsCompatHacks:
  Enabled: true
  CheckUnderscoreAssignments: false  # Optional, off by default
```
