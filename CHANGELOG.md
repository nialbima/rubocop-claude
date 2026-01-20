# Changelog

## [0.0.1] - 2025-01-20

Initial pre-alpha release.

### Added

- `Claude/NoFancyUnicode` - Flags emoji and fancy Unicode characters
- `Claude/TaggedComments` - Requires attribution on TODO/FIXME/NOTE comments
- `Claude/NoCommentedCode` - Detects commented-out code blocks
- `Claude/NoBackwardsCompatHacks` - Catches dead code preserved for compatibility
- `Claude/NoOverlyDefensiveCode` - Flags rescue nil, excessive &. chains, defensive nil checks
- `Claude/ExplicitVisibility` - Enforces consistent visibility style
- `Claude/MysteryRegex` - Flags long regexes that should be constants
- `rubocop-claude init` command for project setup
- StandardRB plugin support via lint_roller
