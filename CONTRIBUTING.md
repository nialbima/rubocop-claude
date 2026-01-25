# Contributing to rubocop-claude

Thanks for your interest in contributing!

## Bug Reports

Use [GitHub Issues](https://github.com/nabm/rubocop-claude/issues) to report bugs. Please include:

- Ruby version (`ruby -v`)
- RuboCop version (`rubocop -v`)
- rubocop-claude version
- Minimal reproduction case
- Expected vs actual behavior

## Feature Requests

Open an issue describing:

- The problem you're trying to solve
- Your proposed solution (if any)
- Example code that would trigger the new cop

## Pull Requests

1. Fork the repo
2. Create a feature branch (`git checkout -b my-new-cop`)
3. Write tests first (we use RSpec)
4. Implement your changes
5. Run the test suite (`bin/rspec`)
6. Run the linter (`bin/rubocop`)
7. Commit with a clear message
8. Push and open a PR

### Development Setup

```bash
git clone https://github.com/nabm/rubocop-claude.git
cd rubocop-claude
bundle install
```

### Running Tests

```bash
bin/rspec              # Run all tests
bin/rspec spec/path    # Run specific tests
```

### Code Style

This project uses RuboCop (including rubocop-claude itself). Before submitting:

```bash
bin/rubocop            # Check for violations
bin/rubocop -a         # Auto-correct safe violations
```

## Adding a New Cop

1. Create the cop in `lib/rubocop/cop/claude/`
2. Add configuration to `config/default.yml`
3. Write specs in `spec/rubocop/cop/claude/`
4. Add documentation to README.md
5. Update CHANGELOG.md

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
