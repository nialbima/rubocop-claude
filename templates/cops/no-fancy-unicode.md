# Claude/NoFancyUnicode

**What it catches:** Non-standard Unicode characters outside the allowed set (letters, numbers, ASCII symbols).

**Why it matters:** Fancy Unicode causes subtle bugs. Curly quotes `""` break string matching. Mathematical symbols `≠` look like `!=` but aren't. Em-dashes `—` aren't hyphens. Emoji reduce professionalism.

## How to Fix

```ruby
# BAD - curly quotes
puts "Hello world"

# BAD - em-dash
# Section 3 — Details

# BAD - mathematical symbol
puts "x ≠ y"

# BAD - emoji
puts "Success! 🎉"
status = :done_✅

# GOOD - ASCII equivalents
puts "Hello world"

# GOOD - double hyphen or just hyphen
# Section 3 -- Details

# GOOD - ASCII operators
puts "x != y"

# GOOD - no emoji
puts "Success!"
status = :done
```

## Allowed Characters

- **Letters** - Any script: Latin, Chinese, Japanese, Cyrillic, Arabic, etc.
- **Numbers** - Any script
- **Combining marks** - Accents, diacritics (café, José)
- **ASCII printable** - All standard keyboard symbols (0x20-0x7E)
- **Whitespace** - Tabs, newlines

## Configuration Options

```yaml
Claude/NoFancyUnicode:
  AllowedUnicode: ['→', '←', '•']  # Specific chars to permit
  AllowInStrings: false            # Skip checking strings
  AllowInComments: false           # Skip checking comments
```

## Common Replacements

| Fancy | ASCII | Description |
|-------|-------|-------------|
| `"` `"` | `"` | Curly quotes to straight quotes |
| `'` `'` | `'` | Curly apostrophes to straight |
| `—` | `--` | Em-dash to double hyphen |
| `–` | `-` | En-dash to hyphen |
| `≠` | `!=` | Not equal |
| `≤` `≥` | `<=` `>=` | Comparison operators |
| `→` `←` | `->` `<-` | Arrows |
| `•` | `*` or `-` | Bullet |

## When to Allow

Add to `AllowedUnicode` if the character is:
- Required by external API or data format
- Part of user-facing content where typography matters
- In comments explaining Unicode behavior
