# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a BATS (Bash Automated Testing System) helpers library that provides assertions, mocking, data providers, step runners, and test utilities for Bash shell testing. It's published as `@drevops/bats-helpers` npm package.

## Architecture

### Core Components

- **load.bash**: Central loading point that sources all helper modules
- **src/**: Contains all helper modules:
  - `assert.*.bash`: Various assertion helpers (base, command, string, file, git)
  - `cleanup.bash`: Deferred cleanup that runs once the current test has finished
  - `retry.bash`: Retry runner for conditions that become true shortly
  - `file.bash`: File utilities for creating, trimming, backing up and restoring files
  - `mock.bash`: Command mocking - the sandbox, mock creation, responses, argument specifications, strictness, the ordered call log and its assertions
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

### Function Naming
Bash has no namespaces: every sourced function lands in one global scope shared with the consumer's own helpers, with bats-assert and bats-file, and with every binary on `PATH`. The prefix is the namespace, so a helper is named `<subject>_<verb>` after the module that owns it - `steps_run`, `mock_setup`, `file_trim`, `fixture_prepare_dir`, `string_random`. This matches how bats-core namespaces `bats_*` and bats-support namespaces `batslib_*`.

Two exceptions:

- **The `assert_*` family** keeps the verb first, because there the verb is already the namespace and it matches bats-assert and bats-file exactly. Shape: `assert_<subject>_<predicate>`, e.g. `assert_file_not_exists`. An assertion a module owns still takes the module's prefix: `mock_assert_call_args`.
- **`flunk` and `format_error`** are bare verbs, mirroring bats-support's `fail`.

The subject naming a helper is what it acts on, not the file it sits in, so the helpers behind those two bare verbs read `report_*` - `report_decorate`, `report_diff`, `report_stack_trace`, `report_normalise_paths` - even though they live in `src/assert.base.bash`. The failure report is the subject they share.

### Variable Naming
Every variable the library reads from the wider environment carries the `BATS_HELPERS_` prefix, for the same namespace reason as the function prefixes: `load.bash` is sourced into the consumer's test shell, so an unprefixed global would collide silently with the consumer's own. The name after the prefix identifies the module and then the subject - `BATS_HELPERS_STEPS_DEBUG`, `BATS_HELPERS_ASSERT_DIR_EXCLUDE`, `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED`. The mocking modules follow it like every other: `BATS_HELPERS_MOCK_TMPDIR`, `BATS_HELPERS_MOCK_USER` and `BATS_HELPERS_MOCK_STRICT`.

`STEPS`, `TEST_CASES` and `SCRIPT_FILE` are the three exceptions and stay unprefixed. They are not environment configuration but the test data itself, written on the lines directly above the call that reads them, so the declaration and its use are read together and a long prefix costs more in daily ergonomics than the collision risk costs in rare confusion. `STEPS` and `TEST_CASES` are arrays declared with `declare -a`; `SCRIPT_FILE` is a scalar path.

A deprecated name is read only when its replacement is unset **or empty**, so exporting the replacement as an empty string falls back rather than taking precedence. Every fallback in the library follows that one rule.

The prefix rule covers what the library provides, not what it consumes - bats-core's own `BATS_TEST_TMPDIR`, `BATS_TMPDIR`, `BATS_TEST_DIRNAME` and `BATS_VERBOSE_RUN` keep their names.

A renamed variable is resolved into a local at the top of the function that owns it, preferring the prefixed name and falling back to the old one with a deprecation notice. The chain is written out in full at each site, for the same reason the function aliases are.

### Assertion Functions
All assertion functions follow the pattern of checking conditions and calling `flunk()` with formatted error messages on failure.

### Match Modes
A match mode is chosen by picking the assertion, never by passing an option or setting a variable. Every combination of the three axes has its own name, so a call site says what it compares without a reader having to resolve a flag: the verb says how the needle is read (`contains`, `starts_with`, `ends_with`, `matches`, `matches_format`), the `not_` prefix negates, and the `_case` suffix matches case-sensitively. Absent that suffix the match ignores case, which is what the library has always done, so no existing assertion changed meaning.

Options were considered and rejected: an assertion argument is then either a needle or a flag depending on its spelling, which costs an escape hatch, and a needle such as `--verbose` stops being a plain string. Naming every cell trades a larger surface for a call site that cannot be misread.

The cost of that trade is 56 near-identical wrappers, so none of them holds logic. `string_assert_match` in `src/assert.string.bash` matches and builds the failure report; `command_assert_match` resolves a needle that may come from STDIN and `file_assert_match` resolves one from disk, then both delegate to it. Every public assertion is a single line passing its anchor, polarity, mode and case sensitivity as literals. Add one by writing that line, never by adding a branch below it.

Matching is Bash-native rather than a `grep` pipeline, which is what lets one engine serve every mode and both anchors. The consequence worth knowing is that `^` and `$` anchor to the whole value rather than to each of its lines, matching how bats-assert reads `--regexp`.

### Failure Message Style
Failure messages are what a consumer reads when their test breaks, so they follow one house style across `src/`, with no exceptions.

Every assertion reports through `format_error <title> [<key> <value>]... | flunk`, which renders one decorated block: a title naming what went wrong, then the values that decided it as aligned rows. A value that spans lines switches every row to a labelled form carrying its line count, so two values stay comparable rather than one collapsing onto a line and the other not; rows keyed `expected` and `actual` are then replaced by a unified diff. `flunk` appends the stack trace and rewrites the volatile paths, so an assertion never does either itself.

- **The title carries no values.** It names the subject and what failed - `File does not exist`, `String does not contain substring`, `Command exited with an unexpected status` - and the paths, strings and counts that fill it in go in rows. A value interpolated into a sentence is unreadable the moment it spans lines, which is the whole reason the rows exist.
- **Open the title with the capitalised subject noun** naming the thing under assertion: `File`, `Directory`, `Symlink`, `Regular file`, `String`, `Line`, `Output`, `Command`. Row keys are lowercase and name the value they hold: `file`, `directory`, `string`, `substring`, `regular expression`, `format`, `expected`, `actual`, `context`.
- **Row values are written raw, not quoted.** The aligned column already bounds the value, and a quote around `insensitive` or `literal` reads as noise. Single quotes stay in the sentences a direct `flunk` call raises, where there is nothing else to bound the value: `Line index '${index}' is not an integer.`
- **Name the pair `expected` and `actual` whenever two values are compared**, and in that order. That is what turns a multi-line mismatch into a diff rather than two blobs.
- **State the actual fact in the title, and append an expectation clause only when the fact alone does not convey it.** A positive assertion states the negated fact with no clause (`Directory is not empty`); a negative assertion states the positive fact plus a clause (`Directory is empty, but should not be`). Use the terse `, but should not` after a plain verb and `, but should not be` after a copula when the expectation is simply the negation; name the expectation outright whenever that is clearer (`Regular file exists, but should be a symlink`, `Command succeeded, but should have failed`).
- **Choose the kind by what the message is about.** `format_error` reports a fact about a subject the caller can go and inspect - a file, a directory, a string, a line - and the subject and its values become the title and the rows. A direct `flunk` raises an error about the call itself: a malformed argument, a missing precondition of the library, a command that could not run. `File does not exist` with a `file` row is the first kind; `Unable to resolve the backup path: file '${file}' contains a parent directory reference.` is the second.
- **Punctuate by message kind**: a `format_error` title takes no trailing full stop; validation and runtime errors raised by a direct `flunk` call read as sentences and end with one; row keys take neither.

### Documentation Style
File headers and function docblocks follow one house style so the library reads as one project, with no exceptions.

- **File headers**: every `.bash` file opens with the `@file` shape. `.bats` files use the plain shape without `@file`. A file-level `shellcheck disable` follows the header, separated by a blank comment line.

```bash
#!/usr/bin/env bash
##
# @file
# Assertions for files and directories.
#
# shellcheck disable=SC2119,SC2120
```

```bash
#!/usr/bin/env bats
#
# Tests for file and directory assertions.
#
```

- **Describe what the file holds**, specifically enough to tell it apart from its siblings. `Assertions for strings.` not `Bats test helpers.`
- **Test file headers** read `Tests for <subject>.`, with the subject lowercase unless it is an acronym: `Tests for git assertions.`, `Tests for TUI helpers.`
- **Function docblocks** are `##`-fenced, open with a third-person summary ending in a full stop, and carry only the sections that add something. `Arguments:` whenever the function takes any, `Globals:` whenever it reads or writes one, `Outputs:` when STDOUT is the result, and `Returns:` only where the return semantics differ from the library norm of "zero, or non-zero via `flunk`". Argument entries are numbered `1. name: Description.`

```bash
##
# Asserts that a directory contains a string.
#
# Arguments:
#   1. dir: Directory to search.
#   2. string: String to search for.
#
# Globals:
#   BATS_HELPERS_ASSERT_DIR_EXCLUDE: Additional directory names to exclude from
#     the search.
##
```

- **Deprecated aliases take no docblock.** The group banner above them and the notice each one prints already name the replacement.
- **Section banners** inside a long function are three lines at the indent of the code they introduce, with a sentence-case title ending in a full stop:

```bash
  ##
  ## Input validation.
  ##
```

- **Punctuate comments as sentences.** A comment that is a sentence ends with a full stop; a `Key: value` label takes neither a capital nor a stop.
- **Coverage markers** pair `# LCOV_EXCL_START` with `# LCOV_EXCL_STOP`. Those are the markers kcov recognises - `LCOV_EXCL_END` is silently ignored, leaving the region open to end of file.

### Mocking System
The mocking system creates temporary mock executables that record calls and can return configured outputs/exit codes.

Everything mock-related lives in one `src/mock.bash`, in the same way the `assert.*` family splits by subject but each subject stays whole. The one rule the single file has to carry itself is the process boundary: the generated mock is a separate script that sources `assert.string.bash` and `mock.bash` and then runs in its own process, where `assert.base.bash` is *not* loaded. Every function that mock reaches at call time - the log writers, the whole matching engine, the response resolution, forwarding, and the strictness accept and reject pair - therefore must never call `flunk`, which would die as an unknown command under the mock's `set -e`. Each of those functions says so in its docblock; add a `flunk` to one and the mock breaks at run time rather than at lint time, so the docblock line is the only guard.

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
- Every assertion is tested for both its positive and its negative behaviour, in one `@test` per assertion

### Assertion Call Style

Both shapes below work for a positive case, so the split is settled here rather than left to each new test.

- **Call the helper bare for a positive case**: `steps_run "assert" "${mocks[@]}"`. The helper's `flunk` returns non-zero, which fails the test under BATS errexit and reports the specific reason against the calling line. The `run` wrapper needs a follow-up `assert_success`, and omitting it discards the result without failing anything.
- **Wrap the call for a negative case**: `run steps_run "assert" "${mocks[@]}"` followed by `assert_failure`. The bare form would abort the test at the `flunk` before reaching the assertion.
- **Declare test data arrays with `declare -a`**: `declare -a STEPS=( ... )`, `declare -a TEST_CASES=( ... )`, `declare -a answers=( ... )`. Helpers read these arrays through BASH dynamic scoping, so the declaration marks the array as an input to the call that follows it.
