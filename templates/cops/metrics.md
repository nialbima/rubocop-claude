# Metrics/* Cops

**What they catch:** Methods that are too complex or too long.

- `Metrics/CyclomaticComplexity` - Too many branching paths
- `Metrics/AbcSize` - Too many assignments, branches, conditions
- `Metrics/MethodLength` - Too many lines

**Why it matters:** Complex methods are hard to understand, test, and maintain.

## How to Fix

### Extract Helper Methods

```ruby
# BAD - one big method
def process_order(order)
  # validate order
  # calculate totals
  # apply discounts
  # process payment
  # send notifications
end

# GOOD - broken into focused methods
def process_order(order)
  validate_order(order)
  totals = calculate_totals(order)
  totals = apply_discounts(totals, order.customer)
  process_payment(order, totals)
  send_notifications(order)
end
```

### Reduce Nesting

```ruby
# BAD - deep nesting
def process(data)
  if data.valid?
    if data.complete?
      if data.authorized?
        # actual work
      end
    end
  end
end

# GOOD - early returns
def process(data)
  return unless data.valid?
  return unless data.complete?
  return unless data.authorized?

  # actual work
end
```

### Simplify Conditionals

```ruby
# BAD - complex conditional
if user.admin? || (user.moderator? && post.reported?) || user.id == post.author_id

# GOOD - named method
if can_moderate_post?(user, post)
```

## Decision Criteria

- If a method triggers these, it probably needs refactoring
- Ask if you're not sure how to split it up
- Don't just add `# rubocop:disable` - that's never the answer
