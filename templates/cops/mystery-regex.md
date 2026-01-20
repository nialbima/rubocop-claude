# Claude/MysteryRegex

**What it catches:** Inline regexes longer than 25 characters (configurable).

**Why it matters:** Complex regexes are cryptic. A named constant with a descriptive name makes the intent clear. Comments can explain what the pattern matches.

## How to Fix

```ruby
# BAD - what does this match?
text.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)

# BAD - still cryptic even in a method
def valid_email?(text)
  text.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
end

# GOOD - name explains intent
EMAIL_PATTERN = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/

def valid_email?(text)
  text.match?(EMAIL_PATTERN)
end

# BETTER - comment explains the pattern
# Matches email addresses: local-part@domain.tld
# Simplified from RFC 5322 - allows common characters only
EMAIL_PATTERN = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
```

## Naming Conventions

| Pattern Type | Naming Examples |
|--------------|-----------------|
| Email | `EMAIL_PATTERN`, `EMAIL_REGEX` |
| URL | `URL_PATTERN`, `HTTP_URL_REGEX` |
| Phone | `PHONE_NUMBER_PATTERN` |
| Date | `ISO_DATE_PATTERN`, `DATE_REGEX` |
| Validation | `VALID_USERNAME_PATTERN` |
| Parsing | `LOG_LINE_PATTERN`, `CSV_ROW_REGEX` |

## When Short Regexes Are Fine

These are OK inline:
- `/\A\d+\z/` - just digits
- `/\s+/` - whitespace
- `/[,;]/` - simple character class
- `/\.rb\z/` - file extension

## Decision Criteria

- Extract to constant if you'd need to think about what it matches
- Always add a comment for non-obvious patterns
- Use `_PATTERN` or `_REGEX` suffix consistently in the project
