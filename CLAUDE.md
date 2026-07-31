# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a BATS (Bash Automated Testing System) helpers library that provides assertions, mocking, data providers, step runners, and test utilities for Bash shell testing. It's published as `@drevops/bats-helpers` npm package.

## Architecture

### Core Components

- **load.bash**: Central loading point that sources all helper modules
- **src/**: Contains all helper modules:
  - `assert.*.bash`: Various assertion helpers (base, command, string, file, git)
  - `file.bash`: File utilities for creating, trimming, backing up and restoring files
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

### Failure Message Style
Failure messages are what a consumer reads when their test breaks, so they follow one house style across `src/`. `src/mock.bash` is exempt: it is a vendored copy of grayhemp/bats-mock and restyling it would widen the divergence from upstream.

- **Open with the capitalised subject noun** naming the thing under assertion: `File`, `Directory`, `Symlink`, `Regular file`, `String`, `Command`, `Function`. Summary labels use sentence case, not Title Case.
- **Single-quote interpolated values** - paths, strings, names - so empty and whitespace-only values stay visible: `File '${file}' does not exist`. Numeric counts and indices stay bare: `exit status ${status}`, `data set ${data_set_idx}`.
- **State the actual fact, and append an expectation clause only when the fact alone does not convey it.** A positive assertion states the negated fact with no clause (`Directory '${dir}' is not empty`); a negative assertion states the positive fact plus a clause (`Directory '${dir}' is empty, but should not be`). Use the terse `, but should not` after a plain verb and `, but should not be` after a copula when the expectation is simply the negation; name the expectation outright whenever that is clearer (`Regular file '${file}' exists, but should be a symlink`, `Command succeeded, but should have failed`).
- **Punctuate by message kind**: assertion failures routed through `format_error` take no trailing full stop; validation and runtime errors raised by a direct `flunk` call read as sentences and end with one; `Key: value` summary labels take neither.

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

### Assertion Call Style

Both shapes below work for a positive case, so the split is settled here rather than left to each new test.

- **Call the helper bare for a positive case**: `run_steps "assert" "${mocks[@]}"`. The helper's `flunk` returns non-zero, which fails the test under BATS errexit and reports the specific reason against the calling line. The `run` wrapper needs a follow-up `assert_success`, and omitting it discards the result without failing anything.
- **Wrap the call for a negative case**: `run run_steps "assert" "${mocks[@]}"` followed by `assert_failure`. The bare form would abort the test at the `flunk` before reaching the assertion.
- **Declare test data arrays with `declare -a`**: `declare -a STEPS=( ... )`, `declare -a TEST_CASES=( ... )`, `declare -a answers=( ... )`. Helpers read these arrays through BASH dynamic scoping, so the declaration marks the array as an input to the call that follows it.
