# Linting

Run `bin/standardrb` (or `bin/rubocop`) before committing. Fix all errors.

## Quick Reference

| Cop | Fix |
|-----|-----|
| **Claude/NoFancyUnicode** | Remove emoji and fancy Unicode. Use ASCII text. |
| **Claude/TaggedComments** | Add attribution: `# TODO: [@handle] description` |
| **Claude/NoCommentedCode** | Delete commented-out code. Use version control. |
| **Claude/NoBackwardsCompatHacks** | Delete dead code. Don't preserve for compatibility. |
| **Claude/NoOverlyDefensiveCode** | Trust internal code. Remove `rescue nil` and excessive `&.` chains. |
| **Claude/ExplicitVisibility** | Use consistent visibility style (grouped or modifier). |
| **Claude/MysteryRegex** | Extract long regexes to named constants. |

## When to Ask

- If a cop seems wrong for this codebase, ask before disabling
- If you're unsure how to fix, ask rather than guessing
- Never add `# rubocop:disable` without discussing first

## Common Patterns

### Tagged Comments
```ruby
# bad
# TODO fix this later

# good
# TODO: [@username] fix this later
```

### Commented Code
```ruby
# bad - delete this, don't comment it out
# def old_method
#   do_something
# end

# good - just delete it, git has history
```

### Defensive Code
```ruby
# bad - swallowing errors
result = dangerous_call rescue nil

# bad - excessive safe navigation
user&.profile&.settings&.value

# bad - defensive nil check
user && user.name

# good - trust internal code
result = dangerous_call
user.profile.settings.value
user.name
```

### Visibility Style

Check `.rubocop.yml` for `EnforcedStyle` (grouped or modifier):

```ruby
# grouped style (default)
class Foo
  def public_method; end

  private

  def private_method; end
end

# modifier style
class Foo
  def public_method; end

  private def private_method; end
end
```
