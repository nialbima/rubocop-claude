# Claude/NoBackwardsCompatHacks

**What it catches:**
1. `_unused = value` patterns (underscore prefix to silence warnings)
2. Constant re-exports with compatibility comments
3. `# removed:`, `# deprecated:`, `# legacy:` comment markers

**Why it matters:** These patterns preserve dead code "helpfully." Dead code should be deleted, not preserved.

## How to Fix

### Underscore Variables

```ruby
# BAD - underscore to silence unused warning
_old_value = previous_calculation
_unused = some_result

# GOOD - just delete the line if value isn't needed
```

### Constant Re-exports

```ruby
# BAD - re-exporting for "compatibility"
OldClassName = NewClassName  # for backwards compatibility

# GOOD - just delete the alias, update callers
```

### Removal Markers

```ruby
# BAD - removal markers
# removed: def old_method; end
# deprecated: use new_method instead
# legacy: keeping for backwards compat

# GOOD - delete the comments, delete the code
```

## Decision Criteria

- If something is unused, **delete it**
- Don't create "compatibility shims" - update the callers
- **NEVER** use underscore prefix to preserve unused values
