# rubocop-claude

"CUT IT OUT, CLAUDE." doesn't work.
"Oh look, somehow you failed linting, how rough for you, better fix it! no naps!" does.

AI assistants are useful and can write functional code. They also:
- Hoard old code in a giant pile (probably so they can stare at how shiny it is)
- Build defensive code fortresses EVERYWHERE.
- Handle explosive errors by adding "okay but what if we just ignored that! look, fixed it!"
- Add comments everywhere and then pretend you wrote them :unamused:
- Reach for the world's least common Unicode symbols and then get confused when you say "stop it."

This gem tries to make them cut that out.

## Installation

Add to your Gemfile:

```ruby
gem 'rubocop-claude', require: false
```

Then run:

```bash
bundle install
rubocop-claude init
```

The `init` command will:
1. Create `.claude/linting.md` with instructions for AI assistants
2. Add `rubocop-claude` to your `.standard.yml` or `.rubocop.yml`

## Manual Setup

Add to `.standard.yml` or `.rubocop.yml`:

```yaml
plugins:
  - rubocop-claude
```

## Cops

| Cop | Description |
|-----|-------------|
| `Claude/NoFancyUnicode` | Flags emoji and fancy Unicode (curly quotes, em-dashes) |
| `Claude/TaggedComments` | Requires attribution on TODO/FIXME/NOTE comments |
| `Claude/NoCommentedCode` | Detects commented-out code blocks |
| `Claude/NoBackwardsCompatHacks` | Catches dead code preserved "for compatibility" |
| `Claude/NoOverlyDefensiveCode` | Flags `rescue nil`, excessive `&.` chains, defensive nil checks |
| `Claude/ExplicitVisibility` | Enforces consistent visibility style (grouped or modifier) |
| `Claude/MysteryRegex` | Flags long regexes that should be extracted to constants |

## Configuration

All cops are enabled by default. Configure in `.rubocop.yml`:

```yaml
Claude/NoFancyUnicode:
  AllowInStrings: true  # Allow emoji in user-facing strings
  AllowedUnicode:
    - "\u2192"  # Allow specific characters

Claude/TaggedComments:
  Keywords:
    - TODO
    - FIXME
    - NOTE
    - HACK

Claude/NoCommentedCode:
  MinLines: 2  # Only flag multi-line blocks (set to 1 for single lines)
  AllowKeep: true  # Allow KEEP [@handle]: comments to preserve code

Claude/NoOverlyDefensiveCode:
  MaxSafeNavigationChain: 1  # Flag 2+ chained &. operators
  AddSafeNavigator: false  # Autocorrect to &. instead of direct call

Claude/ExplicitVisibility:
  EnforcedStyle: grouped  # or 'modifier' for `private def foo`

Claude/MysteryRegex:
  MaxLength: 25
```

## Why These Cops?

### NoFancyUnicode

Me: "Okay, let's log that success."
Claude: A RAINBOW OF OBSCURE SYMBOLS EMERGES FROM THE MISTS.

```ruby
# bad
puts "Deployment successful! 🚀"
logger.info "Task completed ✅"

# good
puts "Deployment successful!"
logger.info "Task completed"
```

### TaggedComments

"You added a comment, and it looks like I added a comment, and that comment is wrong."

```ruby
# bad
# TODO: fix this later

# good
# TODO: [@username] fix this later
```

### NoCommentedCode

"No hoarding."

```ruby
# bad
# def old_implementation
#   do_something_outdated
# end

# good - just delete it
```

### NoBackwardsCompatHacks

"NO HOARDING."

```ruby
# bad
_old_value = previous_calculation  # keeping for reference
OldName = NewName  # backwards compatibility

# good - delete it
```

### NoOverlyDefensiveCode

"YOU ARE BUILDING A DOOMSDAY BUNKER FOR A METHOD THAT CAN'T FAIL, CLAUDE."

```ruby
# bad
result = dangerous_call rescue nil
user&.profile&.settings&.value
user && user.name

# good
result = dangerous_call
user.profile.settings.value
user.name
```

### ExplicitVisibility

"The solution is **NOT** 'make all the private methods visible,' bud."

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

### MysteryRegex

"I have no idea what your 300-character regex does, Claude, because you dumped that on the screen, said 'okay cool fixed' and then got distracted."

```ruby
# bad
if input.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)

# good
EMAIL_PATTERN = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
if input.match?(EMAIL_PATTERN)
```

## Suggested RuboCop Defaults

`rubocop-claude init` also enables some defaults in Rubocop that are aimed at keeping AI coders from getting weird with their Ruby. Full config with rationale in `config/default.yml`.

| Cop | Setting | Why |
|-----|---------|-----|
| `Style/DisableCopsWithinSourceCodeDirective` | Enabled | AI "fixes" linting by disabling cops. No. |
| `Layout/ClassStructure` | Enabled | AI scatters methods randomly. Enforce order. |
| `Style/CommentAnnotation` | `RequireColon: true` | Works with TaggedComments. |
| `Lint/Debugger` | Enabled | AI leaves `binding.pry` in code. |
| `Layout/MultilineMethodCallIndentation` | `indented` | Leading dot, 2-space indent. |
| `Style/SafeNavigation` | `MaxChainLength: 1` | Complements NoOverlyDefensiveCode. |
| `Metrics/CyclomaticComplexity` | `Max: 7` | Flag spaghetti logic. |
| `Metrics/AbcSize` | `Max: 17` | Flag bloated methods. |
| `Metrics/MethodLength` | `Max: 10` | AI writes 80-line methods. 10 is plenty. |
| `Metrics/ClassLength` | `Max: 150` | Catches god classes. |
| `Metrics/ParameterLists` | `Max: 5` | Too many params = needs refactoring. |
| `Style/GuardClause` | Enabled | Early returns > nested conditionals. |
| `Style/RedundantReturn` | Enabled | Ruby returns last expression. |
| `Style/MutableConstant` | `strict` | Always `.freeze` constants. |
| `Lint/UnusedMethodArgument` | Enabled | Dead params = dead code. |
| `Style/NestedTernaryOperator` | Enabled | `a ? (b ? c : d) : e` is unreadable. |
| `Style/OptionalBooleanParameter` | Enabled | `foo(data, true)` - what's true mean? |
| `Naming/MethodParameterName` | `MinNameLength: 2` | No `x`, `y`, `z` params. Use real names. |
| `Style/ParallelAssignment` | Enabled | One assignment per line. |

**Not enabled:** `Lint/SuppressedException` and `Style/RescueModifier` - our `NoOverlyDefensiveCode` covers these with a unified "trust internal code" message.

**AllCops:**
- `NewCops: disable` - No surprise failures on RuboCop upgrade
- `SuggestExtensions: false` - No extension nag messages

## Claude Integration

`rubocop-claude init` will add files to .claude (or elsewhere if you provide it with a path).

These files are a bunch of reference docs for AI agents to gnaw on when they're asked to think about linting. It does not change any of your other config, and it does not try to integrate with the rest of your setup. It's just providing a structured starting point for getting AI agents to lint more effectively.

## WHAT THIS DOES NOT DO

This isn't a subsitute for reviewing your code or monitoring AI assistants. Static analysis is a wonderful tool for wrangling Ai coders, but it does not replace reviewing and monitoring changes.

Trying to force static analysis tools to fully handle every single edge case is silly, and trying to make these weird, enthusiastic pattern recognition engines get everything right on the first try isn't going to work. What we're trying to do is give tools like Claude a way to efficiently remember that they shouldn't be making weird decisions, and that they should make good decisions instead.

We can't always prevent AI tools from charging off in weird directions, but we CAN scatter rakes in their way and make them stop and think. This adds more rakes.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
