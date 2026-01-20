# Claude/TaggedComments

**What it catches:** TODO/FIXME/NOTE/HACK comments without attribution.

**Why it matters:** Anonymous TODOs lose context. Attribution tracks ownership and distinguishes human comments from AI-generated ones.

## How to Fix

```ruby
# BAD
# TODO: Refactor this method
# FIXME: Handle edge case

# GOOD - human attribution
# TODO [@username]: Refactor this method - it's doing too much
# FIXME [Alice - @alice]: Handle edge case where user is nil

# GOOD - AI attribution
# TODO [@claude]: Consider extracting to a service object
# NOTE [@claude]: This mirrors the pattern in user_factory.rb
```

## For AI Assistants

**Your handle is `@claude`.** When you write TODO/FIXME/NOTE/HACK comments, always use `[@claude]`:

```ruby
# TODO [@claude]: This method could be simplified
# NOTE [@claude]: Intentionally duplicated from BaseController for isolation
```

This makes it easy to find AI-generated comments later with `grep -r "@claude"`.

## Attribution Format

Required format: `[@handle]` or `[Name - @handle]`

| Format | Example | Valid |
|--------|---------|-------|
| Handle only | `[@username]` | Yes |
| Name + handle | `[Alice - @alice]` | Yes |
| Full name + handle | `[Alice Smith - @alice]` | Yes |
| No @ symbol | `[username]` | No |
| No handle | `[Alice]` | No |
| Plain text | `[some text]` | No |

## Placement

Attribution can appear anywhere in the comment:

```ruby
# Both valid:
# TODO [@username]: Fix this later
# TODO: Fix this later [@username]
```

## Configuration Options

```yaml
Claude/TaggedComments:
  Keywords:
    - TODO
    - FIXME
    - NOTE      # Default keywords
    - HACK
    - OPTIMIZE
    - REVIEW
```

## When Fixing Existing Comments

- **Your own new comments:** Use `[@claude]`
- **Existing anonymous comments:** Ask the human whose attribution to use
- **Don't guess:** If unsure, ask "Who should I attribute this TODO to?"
