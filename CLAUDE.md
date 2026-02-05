# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a BATS (Bash Automated Testing System) helpers library that provides assertions, mocking, data providers, step runners, and test utilities for Bash shell testing. It's published as `@drevops/bats-helpers` npm package.

## Architecture

### Core Components

- **load.bash**: Central loading point that sources all helper modules
- **src/**: Contains all helper modules:
  - `assert.*.bash`: Various assertion helpers (base, command, string, file, git)
  - `mock.bash`: Command mocking functionality (based on bats-mock)
  - `steps.bash`: Step runner for sequential command and string assertions
  - `dataprovider.bash`: Data provider utilities for parameterized tests
  - `fixture.bash`: Test fixture management
  - `tui.bash`: Terminal UI testing helpers

### Test Structure

- **tests/**: Contains BATS test files (*.bats) that test each helper module
- **tests/_test_helper.bash**: Common test setup that loads the library and sets up mocking
- **tests/fixtures/**: Test fixture files used by tests

## Development Commands

### Testing
```bash
# Run all tests using BATS
./node_modules/.bin/bats tests/

# Run specific test file
./node_modules/.bin/bats tests/assert.base.bats

# Run tests with verbose output
./node_modules/.bin/bats --verbose-run tests/

# Run tests with timing information
./node_modules/.bin/bats --timing tests/
```

### Maintenance Commands (from README)
```bash
# Install dependencies
npm install

# Lint code (shellcheck + shfmt)
npm run lint

# Fix lint issues automatically
npm run lint-fix

# Run tests
npm run test
```

## Key Patterns

### Library Loading
Users load the library by creating a `_loader.bash` file:
```bash
export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/../node_modules"
bats_load_library bats-helpers
```

### Assertion Functions
All assertion functions follow the pattern of checking conditions and calling `flunk()` with formatted error messages on failure.

### Mocking System
The mocking system creates temporary mock executables that record calls and can return configured outputs/exit codes.

### Step Runner
The `steps.bash` module provides a DSL for defining test sequences with both command mocking and string assertions:
- `@<command> # <status> [ # <output> [ # <side_effect> ]]` - Mock command with status/output/side effect
- `<substring>` - Assert output contains substring  
- `- <substring>` - Assert output does NOT contain substring

Side effects are Bash code executed when the mock is called, useful for file creation, environment changes, or complex mock behaviors.

## Testing Notes

- Tests use the `_test_helper.bash` which sets up mocking and loads the library
- Test files follow BATS naming convention (*.bats)
- Coverage reports are generated in the `coverage/` directory
- The library includes comprehensive test coverage for all helper functions