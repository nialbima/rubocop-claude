# Ruby Linting

Run `bin/standardrb` before committing. **All warnings and errors are failures** - fix them before proceeding.

## Quick Reference

When you hit a linting error, read the corresponding guidance file in `.claude/cops/`:

| Cop | Guidance File |
|-----|---------------|
| `Claude/NoFancyUnicode` | `.claude/cops/no-fancy-unicode.md` |
| `Claude/TaggedComments` | `.claude/cops/tagged-comments.md` |
| `Claude/NoCommentedCode` | `.claude/cops/no-commented-code.md` |
| `Claude/NoBackwardsCompatHacks` | `.claude/cops/no-backwards-compat-hacks.md` |
| `Claude/NoOverlyDefensiveCode` | `.claude/cops/no-overly-defensive-code.md` |
| `Claude/ExplicitVisibility` | `.claude/cops/explicit-visibility.md` |
| `Claude/MethodParameterShadowing` | `.claude/cops/method-parameter-shadowing.md` |
| `Claude/MysteryRegex` | `.claude/cops/mystery-regex.md` |
| `Style/DisableCopsWithinSourceCodeDirective` | `.claude/cops/disable-cops-directive.md` |
| `Layout/ClassStructure` | `.claude/cops/class-structure.md` |
| `Metrics/*` | `.claude/cops/metrics.md` |

## Critical Rules

1. **Warnings ARE failures** - Don't ignore them, don't proceed with warnings
2. **Never disable cops inline** - Fix the issue or ask for help
3. **When unsure** - Ask before guessing at a fix
