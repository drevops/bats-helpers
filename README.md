<p align="center">
  <a href="https://bats-helpers.drevops.com" rel="noopener">
 <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=BATS%20helpers&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="BATS helpers logo"></a>
</p>

<h1 align="center">BATS helpers</h1>

<div align="center">

[![GitHub Issues](https://img.shields.io/github/issues/drevops/bats-helpers.svg)](https://github.com/drevops/bats-helpers/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/drevops/bats-helpers.svg)](https://github.com/drevops/bats-helpers/pulls)
[![Test shell](https://github.com/drevops/bats-helpers/actions/workflows/test-shell.yml/badge.svg)](https://github.com/drevops/bats-helpers/actions/workflows/test-shell.yml)
[![codecov](https://codecov.io/gh/drevops/bats-helpers/graph/badge.svg?token=O0ZYROWCCK)](https://codecov.io/gh/drevops/bats-helpers)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/drevops/bats-helpers)
![LICENSE](https://img.shields.io/github/license/drevops/bats-helpers)
![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot)
</div>

---

<p align="center"> Helpers and assertions for <a href="https://github.com/bats-core/bats-core">BATS</a> testing.
</p>

## Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Usage](#-usage)
  - [Load library](#load-library)
  - [Assertions](#assertions) - Command run, Line, Exit statuses, Standard error, String, Match modes, File, Git
  - [Data provider](#data-provider) - Parameterized tests
  - [Mocking](#mocking) - Command mocking, Call log, Argument specifications, Strictness
  - [Step runner](#step-runner) - Sequential test assertions
  - [Helpers](#helpers) - Utility functions
  - [Environment variables](#environment-variables) - Full variable reference
  - [Deprecations](#deprecations) - Renamed functions and variables
- [Acknowledgments](#-acknowledgments)
- [Contributing](#-contributing)

## ✨ Features

- Assertions for command output, its individual lines, exit status, standard error, strings, files, directories and git repositories.
- Literal, regular expression and format matching, with case sensitivity as an explicit choice.
- Command mocking with per-call output, exit status and side effects, and responses selected by matched arguments.
- An ordered log of every mocked call, asserted as a sequence and reported as a unified diff.
- Mock expectations that fail the test when they go unused or when an unanticipated call arrives.
- Step runner for sequences of mocked calls and output assertions.
- Data provider for running one function over many test cases.
- Fixture and file utilities for building and restoring test sandboxes.
- TUI helper for driving interactive scripts with scripted answers.

## 📦 Installation

Requires [bats-core](https://github.com/bats-core/bats-core) `1.13` or newer, and Bash `4.0` or newer. macOS ships Bash `3.2`, so install a current one with `brew install bash`.

### NPM

```shell
npm install -D bats-helpers@npm:@drevops/bats-helpers
```

This will also install `bats-core`.

### From source

1. Click `Code` -> `Download ZIP` in the [GitHub UI](https://github.com/drevops/bats-helpers).
2. Extract files to a desired location. Usually, next to where `bats-core` is located.

## 🚀 Usage

### Load library

Create a `_loader.bash` file next to your BATS tests with content:

```bash
# For NPM installation:
export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/../node_modules"

# For source installation:
# export BATS_LIB_PATH="<path/to/extracted/files>"

bats_load_library bats-helpers
```

Then use `load _loader.bash` in every BATS test file:

```bats
#!/usr/bin/env bats
load _loader.bash

@test "My test" {
 run ls
 assert_success
}
```

### Assertions

#### Command run assertions

Use these after running a command with `run`.

| Function Name                | Description                                            |
|------------------------------|--------------------------------------------------------|
| `assert_success`             | Asserts that a command succeeds                        |
| `assert_failure`             | Asserts that a command fails                           |
| `assert_output`              | Asserts that a command outputs an exact string         |
| `assert_output_contains`     | Checks if output contains a specific string            |
| `assert_output_not_contains` | Checks if output does not contain a specific string    |
| `assert_output_matches`      | Checks if output matches a regular expression          |
| `assert_output_not_matches`  | Checks if output does not match a regular expression   |
| `assert_output_matches_format`     | Checks if output matches a format string         |
| `assert_output_not_matches_format` | Checks if output does not match a format string  |

The six `contains`, `matches` and `matches_format` assertions each have a `_case` twin that matches case-sensitively - `assert_output_contains_case`, `assert_output_not_matches_format_case` and so on. See [Match modes](#match-modes).

#### Line assertions

`run` also splits what it captured into `${lines[@]}`. These assert against a line rather than against the output as a whole, which is what a command-line tool's output is usually shaped like.

Assert a line by index. A negative index counts back from the end, so `-1` is the last line:

| Function Name                    | Description                                                        |
|----------------------------------|--------------------------------------------------------------------|
| `assert_line`                    | Asserts that the line at an index equals a string                  |
| `assert_line_not`                | Asserts that the line at an index does not equal a string          |
| `assert_line_contains`           | Checks if the line at an index contains a string                   |
| `assert_line_not_contains`       | Checks if the line at an index does not contain a string           |
| `assert_line_matches`            | Checks if the line at an index matches a regular expression        |
| `assert_line_not_matches`        | Checks if the line at an index does not match a regular expression |
| `assert_line_matches_format`     | Checks if the line at an index matches a format string             |
| `assert_line_not_matches_format` | Checks if the line at an index does not match a format string      |

Assert that some line matches, without pinning which one. The positive reads `any`, the negative reads `no`:

| Function Name                       | Description                                            |
|-------------------------------------|--------------------------------------------------------|
| `assert_any_line`                   | Asserts that some line equals a string                 |
| `assert_no_line`                    | Asserts that no line equals a string                   |
| `assert_any_line_contains`          | Checks if some line contains a string                  |
| `assert_no_line_contains`           | Checks if no line contains a string                    |
| `assert_any_line_matches`           | Checks if some line matches a regular expression       |
| `assert_no_line_matches`            | Checks if no line matches a regular expression         |
| `assert_any_line_matches_format`    | Checks if some line matches a format string            |
| `assert_no_line_matches_format`     | Checks if no line matches a format string              |

Assert how many lines there are, or how many of them a needle matches:

| Function Name                        | Description                                                |
|--------------------------------------|------------------------------------------------------------|
| `assert_line_count`                  | Asserts the number of lines                                |
| `assert_line_count_not`              | Asserts that the number of lines differs                   |
| `assert_line_count_contains`         | Asserts how many lines contain a string                    |
| `assert_line_count_not_contains`     | Asserts how many lines do not contain a string             |
| `assert_line_count_matches`          | Asserts how many lines match a regular expression          |
| `assert_line_count_not_matches`      | Asserts how many lines do not match a regular expression   |
| `assert_line_count_matches_format`   | Asserts how many lines match a format string               |
| `assert_line_count_not_matches_format` | Asserts how many lines do not match a format string      |

Every `contains`, `matches` and `matches_format` assertion above has a `_case` twin that matches case-sensitively - `assert_line_contains_case`, `assert_no_line_matches_case`, `assert_line_count_not_contains_case` and so on. `assert_line`, `assert_line_not`, `assert_any_line`, `assert_no_line` and the two `assert_line_count` assertions compare exactly and have no twin. See [Match modes](#match-modes).

`not` negates whatever follows it. Where a verb follows, it negates the match, exactly as it does elsewhere in the library: `assert_line_count_not_contains 3 "error"` asserts that three lines do **not** contain `error`, not that the number of lines containing it is other than three. Where nothing follows it - `assert_line_not`, `assert_line_count_not` - there is no verb to negate, so it negates the assertion's own comparison:

```bash
run ./script.sh

assert_line 0 "Usage: script.sh [options]"
assert_line -1 "Done."
assert_line_contains 2 "config"
assert_any_line_matches 'Deleted [0-9]+ files'
assert_no_line_contains "Warning"
assert_line_count 4
assert_line_count_contains 2 "error"
```

An index outside the captured lines is an error naming both the index and the number of lines, rather than a comparison against an empty string that would read as an ordinary mismatch:

```text
Line index 5 is out of range for output with 2 lines.
```

A failure shows the offending line in context rather than the whole stream. The mark overwrites the indent instead of being inserted, so the lines stay in the same column:

```text
Line 2 does not contain 'error'
match mode: literal
case: insensitive

  0: Usage: tool.sh
  1: Reading config
> 2: all good
  3: Done.
```

##### Empty lines and indices

`run` drops empty lines unless it is asked to keep them, so an empty line is not an element of `${lines[@]}` and every index after it shifts up. Pass `--keep-empty-lines` when the blank lines are part of what is being asserted, or when an index has to line up with the output as it was printed:

```bash
bats_require_minimum_version 1.13.0

# 'lines' holds 'first' and 'third'; the empty line is not an element.
run printf '%s\n' "first" "" "third"
assert_line_count 2
assert_line 1 "third"

# 'lines' holds all three, and the indices match the printed output.
run --keep-empty-lines printf '%s\n' "first" "" "third"
assert_line_count 3
assert_line 1 ""
assert_line 2 "third"
```

As with `--separate-stderr`, that declaration has to be `1.5.0` or newer, or bats-core prints a `BW02` warning for every `run` that carries a flag.

#### Exit statuses

| Function Name                     | Description                                             |
|-----------------------------------|---------------------------------------------------------|
| `assert_status`                   | Asserts that a command exits with an exact status       |
| `assert_status_general_error`     | Asserts that a command exits with status `1`            |
| `assert_status_command_not_found` | Asserts that a command exits with status `127`          |

`assert_success` and `assert_failure` divide the world into zero and non-zero, which is not enough for a tool that separates a usage error from a runtime failure by exiting `2` rather than `1`. Assert the status itself:

```bash
run ./script.sh --nonsense

assert_status 2
```

`assert_failure` takes the same expectation through a `--status` option, so that one call still covers both the failure and the status it failed with:

```bash
run ./script.sh --nonsense

assert_failure --status 2
assert_failure --status 2 "Usage: script.sh [--verbose] <path>"
```

The option is recognised only as the first argument, and everything after it and its value is the exact output, as before. An output that is itself the string `--status` is asserted with `assert_output` instead.

##### Statuses that mean more than a failure

Two statuses mean something other than the code under test deciding to fail, and both satisfy a bare `assert_failure` exactly as well as the intended error path does. Every report that prints a status names them:

```text
Command exited with an unexpected status
expected: 2
actual:   127 (command not found)
```

```text
Command failed with exit status 137 (killed by SIGKILL)
```

A status of `127` is what a shell returns for a command it could not find, so a test that passes because the binary under test is missing is caught rather than counted. A status above `128` is how a shell reports a process a signal killed, and the signal is named from the running platform's own table. A program is free to exit with such a status of its own accord, so the name says which signal the number stands for, not that a signal was necessarily involved.

Where a missing command *is* the expected outcome, assert it as such:

```bash
# 'run -127' stops bats warning about the status it would otherwise read as a
# mistake in the test.
run -127 ./wrapper.sh

assert_status_command_not_found
```

#### Standard error assertions

| Function Name                | Description                                                 |
|------------------------------|-------------------------------------------------------------|
| `assert_stderr`              | Asserts that a command writes an exact string to STDERR     |
| `assert_stderr_contains`     | Checks if STDERR contains a specific string                 |
| `assert_stderr_not_contains` | Checks if STDERR does not contain a specific string         |
| `assert_stderr_matches`      | Checks if STDERR matches a regular expression               |
| `assert_stderr_not_matches`  | Checks if STDERR does not match a regular expression        |
| `assert_stderr_matches_format`     | Checks if STDERR matches a format string              |
| `assert_stderr_not_matches_format` | Checks if STDERR does not match a format string       |
| `assert_stderr_empty`        | Asserts that a command wrote nothing to STDERR              |
| `assert_stderr_captured`     | Asserts that STDERR was captured separately from the output |

The six `contains`, `matches` and `matches_format` assertions each have a `_case` twin that matches case-sensitively. See [Match modes](#match-modes).

`run` merges STDERR into `$output`, so on its own it cannot tell which stream a message went to. Pass `--separate-stderr` to capture the two apart: `$output` then holds STDOUT alone, and the assertions above read the captured STDERR.

```bash
bats_require_minimum_version 1.13.0

@test "the script warns without polluting stdout" {
  run --separate-stderr ./script.sh

  assert_success
  assert_output "the result"
  assert_stderr_contains "Warning:"
}
```

Without a `bats_require_minimum_version` declaration of `1.5.0` or newer, bats-core prints a `BW02` warning for every `run` that carries a flag.

Each of these assertions fails when `--separate-stderr` is missing, instead of comparing against a value that was never captured:

```text
Stderr was not captured. Run the command with 'run --separate-stderr'.
```

The check matters most for `assert_stderr_empty`, which would otherwise pass for a command that did write to STDERR - the stream having simply never been captured. Use `assert_stderr_captured` to make the same check on its own.

A captured STDERR that is not empty is appended to failure reports, so a command that failed shows why rather than only that it did:

```text
Command failed with exit status 3

----------------------------------------
stderr:
Error: config file not found
----------------------------------------
```

A capture lives only until the next `run`: a plain one clears `$stderr`, so the assertions always read the most recent `run --separate-stderr`. Pass the option to the `run` whose STDERR is being asserted on, and assert directly after it.

#### String assertions

| Function Name                   | Description                                               |
|---------------------------------|-----------------------------------------------------------|
| `assert_empty`                  | Asserts that a string is empty                            |
| `assert_not_empty`              | Asserts that a string is not empty                        |
| `assert_equal`                  | Asserts that two strings are equal                        |
| `assert_string_contains`        | Asserts that a string contains a given substring          |
| `assert_string_not_contains`    | Asserts that a string does not contain a substring        |
| `assert_string_starts_with`     | Asserts that a string starts with a substring             |
| `assert_string_not_starts_with` | Asserts that a string does not start with a substring     |
| `assert_string_ends_with`       | Asserts that a string ends with a substring               |
| `assert_string_not_ends_with`   | Asserts that a string does not end with a substring       |
| `assert_string_matches`         | Asserts that a string matches a regular expression        |
| `assert_string_not_matches`     | Asserts that a string does not match a regular expression |
| `assert_string_matches_format`     | Asserts that a string matches a format string          |
| `assert_string_not_matches_format` | Asserts that a string does not match a format string   |

Every assertion below `assert_equal` has a `_case` twin that matches case-sensitively - `assert_string_contains_case`, `assert_string_not_starts_with_case` and so on. `assert_empty`, `assert_not_empty` and `assert_equal` compare exactly and have no twin. See [Match modes](#match-modes).

Every `contains` assertion takes the container first and the string to look for second:

```bash
assert_string_contains "some needle in a haystack" "needle"
assert_file_contains "${file}" "needle"
assert_dir_contains_string "${dir}" "needle"
```

#### Match modes

How a needle is read, and whether case matters, is chosen by picking the assertion - there are no options to pass. Every combination has a name, so a call site says what it compares without being read against a flag elsewhere in the file.

Three things vary. **How the needle is read** is the verb:

| Verb             | The needle is                             |
|------------------|-------------------------------------------|
| `contains`       | A literal substring                       |
| `starts_with`    | A literal prefix                          |
| `ends_with`      | A literal suffix                          |
| `matches`        | An extended regular expression            |
| `matches_format` | A format string, see below                |

**Whether it must be present** is the `not_` prefix, and **whether case matters** is the `_case` suffix. Absent the suffix, the match ignores case, which is what the library has always done:

```bash
assert_output_contains            "Deleted 12 files"    # ignores case
assert_output_contains_case       "Deleted 12 files"    # case-sensitive
assert_output_not_contains        "Removed"
assert_output_not_contains_case   "removed"

assert_output_matches             'Deleted [0-9]+ files'
assert_output_matches_case        'Deleted [0-9]+ files'
assert_output_matches_format      "Deleted %d files"

assert_string_starts_with_case    "${line}" "WARNING"
assert_file_not_matches_case      "${log}" 'FATAL'
```

The same twelve names exist for each of `string`, `output`, `stderr` and `file`, and the four prefix and suffix forms for `string`. A needle is only ever a needle, so one that looks like an option needs no escaping:

```bash
assert_output_contains "usage: --verbose enables logging"
```

**Prefer a literal assertion.** A literal needle cannot be broken by a character that happens to be a regular expression operator, and its failure report can be read straight against the value it did not match. Reach for `matches` only for the part of a value that genuinely varies between runs - a timestamp, a PID, a duration, a version - and leave the rest literal. Where the only variation is a number or a word, `matches_format` says so without a regular expression:

| Placeholder | Matches                                   |
|-------------|-------------------------------------------|
| `%d`        | A run of digits                           |
| `%f`        | A number with an optional fractional part |
| `%s`        | A run of non-whitespace characters        |
| `%%`        | A literal `%`                             |

Everything outside a placeholder is matched literally, so a format string escapes nothing of its own:

```bash
assert_output_matches_format "Deleted %d files in %fs"
assert_file_matches_format "${log}" "user %s logged in"
```

The prefix and suffix assertions, and the `^` and `$` anchors of a regular expression, all apply to the whole value rather than to each of its lines:

```bash
# The whole output is 'Done', not merely one of its lines.
assert_output_matches '^Done$'
```

A needle that is not a usable regular expression is reported as an error rather than as a mismatch, so a `not_matches` assertion fails on it too:

```text
Invalid regular expression '['.
```

The failure report names the mode and the case sensitivity that were in force, and calls out the case sensitivity when the other choice would have decided the assertion the other way:

```text
String 'some text' does not contain 'SOME'
match mode: literal
case: sensitive
note: it matches without the '_case' suffix
```

Use `string_match` to make the same comparison without asserting on it, and `string_format_to_regex` to see what a format string expands to. Both take plain values rather than any of the names above:

```bash
# Haystack, needle, mode, case sensitivity, anchor.
string_match "Deleted 12 files" "deleted" "literal" 0 "start"

# Prints 'Deleted [0-9]+ files'.
string_format_to_regex "Deleted %d files"
```

`string_match` returns `0` when the needle matches, `1` when it does not, and `2` when the needle is not a usable regular expression. It reports through the exit status alone and prints nothing.

#### File assertions

| Function Name                    | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `assert_file_exists`             | Asserts that a file exists                             |
| `assert_file_not_exists`         | Asserts that a file does not exist                     |
| `assert_file_contains`           | Checks if a file contains a specific string            |
| `assert_file_not_contains`       | Checks if a file does not contain a specific string    |
| `assert_file_matches`            | Checks if a file matches a regular expression          |
| `assert_file_not_matches`        | Checks if a file does not match a regular expression   |
| `assert_file_matches_format`     | Checks if a file matches a format string               |
| `assert_file_not_matches_format` | Checks if a file does not match a format string        |
| `assert_files_equal`             | Asserts that two files are equal                       |
| `assert_files_not_equal`         | Asserts that two files are not equal                   |
| `assert_file_mode`               | Checks the file permission mode                        |
| `assert_binary_files_equal`      | Checks if two binary files are equal                   |
| `assert_binary_files_not_equal`  | Checks if two binary files are not equal               |
| `assert_dir_exists`              | Asserts that a directory exists                        |
| `assert_dir_not_exists`          | Asserts that a directory does not exist                |
| `assert_dir_empty`               | Asserts that a directory is empty                      |
| `assert_dir_not_empty`           | Asserts that a directory is not empty                  |
| `assert_dir_contains_string`     | Checks if directory contains a specific string         |
| `assert_dir_not_contains_string` | Checks if directory does not contain a specific string |
| `assert_dirs_equal`              | Asserts that two directories are equal                 |
| `assert_symlink_exists`          | Asserts that a symbolic link exists                    |
| `assert_symlink_not_exists`      | Asserts that a symbolic link does not exist            |

The six `contains`, `matches` and `matches_format` assertions each have a `_case` twin that matches case-sensitively - `assert_file_contains_case`, `assert_file_not_matches_format_case` and so on. See [Match modes](#match-modes).

`assert_file_exists` and `assert_file_not_exists` accept a glob. Only the first match decides the outcome, and the failure is reported once however many paths the glob expands to:

```bash
assert_file_exists "${dir}/*.txt"
assert_file_not_exists "${dir}/*.rtf"
```

`assert_dir_contains_string` and `assert_dir_not_contains_string` search recursively, skip binary files, and always exclude `.git`, `.idea`, `vendor` and `node_modules`. They have no match mode variants: they always match case-sensitively and always read the string as a `grep` basic regular expression. Set `BATS_HELPERS_ASSERT_DIR_EXCLUDE` to an array of additional directory names to exclude:

```bash
declare -a BATS_HELPERS_ASSERT_DIR_EXCLUDE=("build" "dist")
assert_dir_contains_string "${dir}" "needle"
```

#### Git assertions

| Function Name                 | Description                                      |
|-------------------------------|--------------------------------------------------|
| `assert_git_repo`             | Asserts that a directory is a git repository     |
| `assert_git_not_repo`         | Asserts that a directory is not a git repository |
| `assert_git_clean`            | Asserts that a git repository is clean           |
| `assert_git_not_clean`        | Asserts that a git repository is not clean       |
| `assert_git_file_tracked`     | Checks if a file is tracked in git               |
| `assert_git_file_not_tracked` | Checks if a file is not tracked in git           |

`assert_git_file_tracked` and `assert_git_file_not_tracked` report through the exit status alone and print no message.

### Data provider

Run multiple test cases for a given function (aka "data provider").

Arguments:

1. `func_name`: The name of the function to be tested.
2. `args_per_row`: (Optional) The number of arguments in each row of the `TEST_CASES` array, defaults to `1`. Last argument is always the expected value.

Global Variables:

- `TEST_CASES`: An array containing test cases with their expected values.

**Examples:**

To run a function `add_numbers` with `TEST_CASES` containing three arguments per row, you can call `dataprovider_run` like so:

```bash
# Function to test.
add_numbers() {
  echo "$(($1 + $2))"
}

@test "Test add_numbers" {
  # Numbers: first two are inputs, last is expected output.
  declare -a TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "add_numbers" 3
}
```

### Mocking

This Bats helper library provides command mocking functionality for BATS.

It allows to mock commands and check how they were called.

This is a very powerful feature that allows to test complex scenarios as unit tests.

> [!NOTE]
> To run multiple mock assertions in a more convenient way, check out the [Step runner](#step-runner) helper.

#### Setup functions

| Function                | Description                                                | Arguments                        | Returns   |
|-------------------------|------------------------------------------------------------|----------------------------------|-----------|
| `mock_setup`            | Setup mock support. Call from `setup()`                    | None                             | None      |
| `mock_create`           | Creates a mock program that can be tracked                 | None                             | Mock path |
| `mock_command`          | Mock provided command                                      | `command_name`                   | Mock path |
| `mock_set_output`       | Sets the output of the mock                                | `mock`, `output`, `[call_index]` | None      |
| `mock_set_status`       | Sets the exit status of the mock                           | `mock`, `status`, `[call_index]` | None      |
| `mock_set_side_effect`  | Sets shell code to run when mock executes                  | `mock`, `code`, `[call_index]`   | None      |
| `mock_set_strict`       | Rejects the calls the mock's expectations do not cover     | `mock`, `[enabled]`              | None      |
| `mock_set_forward`      | Runs the real command for calls no specification accepts   | `mock`, `[enabled]`              | None      |
| `mock_spec_add`         | Adds an argument specification to the mock                 | `mock`                           | Spec      |
| `mock_spec_arg`         | Constrains one argument position of a specification        | `spec`, `position`, `matcher`, `[value]` | None |
| `mock_spec_count`       | Pins the number of arguments a specification accepts       | `spec`, `count`                  | None      |
| `mock_spec_set_output`  | Sets the output a specification responds with              | `spec`, `output`                 | None      |
| `mock_spec_set_status`  | Sets the exit status a specification responds with         | `spec`, `status`                 | None      |
| `mock_spec_set_side_effect` | Sets shell code a specification runs                   | `spec`, `code`                   | None      |
| `mock_log_exclude`      | Excludes commands from sequence comparisons                | `command_name...`                | None      |

#### Assertion functions

| Function                 | Description                                                                    | Arguments                               | Returns          |
|--------------------------|--------------------------------------------------------------------------------|-----------------------------------------|------------------|
| `mock_get_call_args`     | Returns arguments the mock was called with                                     | `mock`, `[call_index]`                  | Arguments string |
| `mock_get_call_num`      | Returns number of times mock was called                                        | `mock`                                  | Call count       |
| `mock_get_call_user`     | Returns user the mock was called with                                          | `mock`, `[call_index]`                  | User name        |
| `mock_get_call_env`      | Returns env variable value from mock call                                      | `mock`, `var_name`, `[call_index]`      | Variable value   |
| `mock_assert_call_args`  | Checks the arguments the mock was called with, where `*` matches any arguments | `mock`, `expected_args`, `[call_index]` | `0` when matched |
| `mock_assert_calls`      | Asserts the ordered sequence of every mocked call                              | `expected_call...`                      | None             |
| `mock_assert_no_calls`   | Asserts that no mocked command outside the excluded ones was called            | None                                    | None             |
| `mock_assert_called`     | Asserts that a command was called                                              | `command_name`                          | None             |
| `mock_assert_not_called` | Asserts that a command was not called                                          | `command_name`                          | None             |
| `mock_verify`            | Asserts that every expectation was met                                         | `[mock...]`                             | None             |
| `mock_log_print`         | Returns every recorded call, in order                                          | None                                    | Call log         |

#### Mock sandbox

`mock_setup` writes the mocks to `${BATS_TEST_TMPDIR}/bats-mock-tmp` and puts that directory first on `PATH`, so BATS removes the mocks together with the rest of the test sandbox and concurrent runs cannot delete each other's mocks.

Set `BATS_HELPERS_MOCK_TMPDIR` to store them elsewhere; the mocks are written to a `bats-mock-tmp` directory below it. The guarantees above come from staying within the test sandbox - a directory outside `${BATS_TEST_TMPDIR}` is not removed by BATS and is shared with concurrent runs:

```bash
export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/mocks"
```

`mock_setup` also exports `BATS_HELPERS_MOCK_TMPDIR` with the resolved path, so a test can read back where the mocks ended up.

`mock_get_call_user` reports the user each call was made as. It defaults to `id -un`; set `BATS_HELPERS_MOCK_USER` to report a different one:

```bash
export BATS_HELPERS_MOCK_USER="deploy"
```

#### Call log

Every mock appends each of its calls to one log shared by the whole test, so the order in which *different* commands ran is assertable. For a script whose correctness is its order of operations, that is usually the assertion that matters most:

```bash
mock_command "git" >/dev/null
mock_command "curl" >/dev/null

run ./deploy.sh

mock_assert_calls \
  "git 'clone' 'https://example.com/repo.git'" \
  "curl '-s' 'https://example.com/hook'" \
  "git 'checkout' 'main'"
```

A mismatch is reported as a unified diff, so the failure shows what ran instead of only that the two sequences differ.

Each line is the command name followed by its arguments, every argument wrapped in single quotes. The quotes are not optional: they keep an empty argument visible as `''` and an argument holding whitespace a single field. Inside the quotes four characters are escaped, so no two distinct arguments serialise the same way:

| Character    | Serialised as |
|--------------|---------------|
| `\`          | `\\`          |
| `'`          | `\'`          |
| Tab          | `\t`          |
| Newline      | `\n`          |

```bash
mock_command "git" >/dev/null

git commit -m "first line
second line" ""

mock_assert_calls "git 'commit' '-m' 'first line\nsecond line' ''"
```

`mock_assert_no_calls` asserts that nothing ran at all, and `mock_assert_called` and `mock_assert_not_called` ask about one command. The last two take a command name rather than a mock path and fail when no mock is registered under that name, so a typo cannot pass by describing a command that was never mocked:

```bash
mock_command "git" >/dev/null

mock_assert_not_called "git"

# Fails with "Command 'gti' is not mocked", rather than passing trivially.
mock_assert_not_called "gti"
```

A command that runs constantly - a logger, an echo - would otherwise have to appear in every expected sequence in the suite. `mock_log_exclude` keeps such a command recorded and visible to `mock_log_print`, `mock_assert_called` and `mock_assert_not_called`, while `mock_assert_calls` and `mock_assert_no_calls` skip it:

```bash
mock_command "logger" >/dev/null
mock_log_exclude "logger"
```

#### Argument specifications

A response set with a call index answers the first call, the second call, and so on, which means the test has to know the order in which the script happens to invoke the command. An argument specification selects the response by what the call passes instead, so reordering the script without changing its behaviour leaves the test standing:

```bash
mock_git="$(mock_command "git")"

status="$(mock_spec_add "${mock_git}")"
mock_spec_arg "${status}" 1 equals "status"
mock_spec_set_output "${status}" "nothing to commit"

push="$(mock_spec_add "${mock_git}")"
mock_spec_arg "${push}" 1 equals "push"
mock_spec_arg "${push}" '*' equals "--force"
mock_spec_set_status "${push}" 1
mock_spec_set_output "${push}" "rejected"
```

Both forms coexist. A call is answered by the first specification that accepts it, in the order the specifications were added; a call that none of them accepts falls back to the response for that call index, and then to the response set without one.

The first argument of `mock_spec_arg` after the specification is the position: a one-based argument index, or `*` for "some argument". The second is the matcher:

| Matcher       | Accepts when the argument                     |
|---------------|-----------------------------------------------|
| `equals`      | is exactly the value                          |
| `starts_with` | starts with the value                         |
| `ends_with`   | ends with the value                           |
| `contains`    | holds the value anywhere                      |
| `matches`     | matches the value as an extended regexp       |
| `present`     | exists, whatever its value. Takes no value    |

Every matcher takes a `not_` prefix. At a numeric position it negates that one argument; at `*` it requires that *no* argument matches, which is the negation of "some argument matches":

```bash
# Argument 2 is not a tag.
mock_spec_arg "${spec}" 2 not_matches '^v[0-9]+$'

# No argument is '--force'.
mock_spec_arg "${spec}" '*' not_equals "--force"
```

Matching is case-sensitive, because a command's arguments are literal. `mock_spec_count` pins how many arguments the call carries:

```bash
mock_spec_count "${spec}" 2
```

A numeric position may be constrained only once per specification. Constraining it twice is rejected when the specification is configured rather than silently resolved at call time, since the outcome would otherwise depend on which of the two constraints was consulted first. Repeating `*` is allowed, and each repetition is a separate requirement.

`mock_set_forward` runs the real command for the calls no specification accepts, which is what makes partial mocking possible:

```bash
mock_curl="$(mock_command "curl")"
mock_set_forward "${mock_curl}"

# Only the health check is answered by the mock; every other call is real.
spec="$(mock_spec_add "${mock_curl}")"
mock_spec_arg "${spec}" '*' ends_with "/health"
mock_spec_set_output "${spec}" "OK"
```

The real command is found by searching `PATH` without the mock directory. A forwarded call is recorded in the call log like any other, and forwarding takes precedence over the response set without a call index.

#### Strictness

> [!IMPORTANT]
> Mocks are strict by default. Once a response carrying a call index or an argument specification has declared an expectation, a call that the expectations do not cover fails the test rather than being answered with the default status and output. Set `BATS_HELPERS_MOCK_STRICT=0` to make a whole suite permissive.

A mock with no configured response records calls without constraining them. Configuring a response *with* a call index, or adding an argument specification, declares an expectation - a statement that the call arrives. From then on the mock rejects the calls its expectations do not cover, rather than answering them with the default status and output and letting the script take a path the test does not know about:

```bash
mock_git="$(mock_command "git")"
mock_set_status "${mock_git}" 0 1

git status

# Fails the call, writing "Mock 'git' received a call that no expectation
# covers: git 'log'" to STDERR and exiting non-zero.
git log
```

When the mock carries argument specifications, the diagnostic lists what each of them required, so the mismatch reads beside the call that caused it:

```text
Mock 'git' received a call that no expectation covers: git 'log' '--oneline'
  specification 1: argument 1 equals 'status'
  specification 2: argument 1 equals 'push', some argument not_equals '--force'
```

A response set *without* a call index is a catch-all that answers everything, so it exempts the mock from strictness. That is the per-mock escape hatch, `mock_set_strict "${mock_git}" 0` is the explicit one, and `BATS_HELPERS_MOCK_STRICT` is the suite-wide one:

```bash
setup() {
  mock_setup
  export BATS_HELPERS_MOCK_STRICT=0
}
```

The strictness of a mock is fixed when the mock is created, so a suite-wide default has to be set before the first `mock_command` call.

The other half of a mock that verifies nothing is an expectation that is never satisfied: a test can declare a response for a call that never arrives and still pass. `mock_verify` reports both that and any call that arrived unexpectedly. Call it from `teardown()` to cover every test in a file:

```bash
teardown() {
  mock_verify
}
```

With no arguments it verifies every mock of the test; with arguments it verifies only the mocks named. The [step runner](#step-runner) calls it for its own mocks at the end of the assert phase.

#### Example

```bash
setup() {
  mock_setup
}

# Test notify.sh, which uses curl to notify an external system.
@test "Notify" {
  app_id="9876543210"

  # Mock curl command.
  mock_curl="$(mock_command "curl")"

  # Setup mock responses for the curl calls made by notify.sh.
  mock_set_output "${mock_curl}" "12345678910-1234567890-${app_id}-12345" 1
  mock_set_output "${mock_curl}" "201" 2

  run ./notify.sh
  assert_success

  # Single line mock assertion example.
  assert_equal "-s -X GET https://api.example.com/v2/applications.json" \
    "$(mock_get_call_args "${mock_curl}" 1)"

  # Multi-line mock assertion example.
  url="https://api.example.com/v2/applications/${app_id}/deployments.json"
  assert_equal "-X POST ${url} -d {
  \"deployment\": {
    \"description\": \"example description\",
  }
}" "$(mock_get_call_args "${mock_curl}" 2)"
}
```

### Step runner

When working with mocks, you would have to setup a mock for each command call with the expected argument numbers, return value, possible output and an index of the call. Then, you would run the code to be tested and run assertions for each of the mocked commands. For large scripts maintaining both parts becomes a tedious task.

The step runner allows to setup and process a sequence of string and mocked command assertions. It helps to make maintenance of complex tests easier.

Consider this example:

```bash
# Declare STEPS as a global variable, as `steps_run` needs to be called
# twice and it does not store the steps internally.
declare -a STEPS=(
  # Mock command with exit status only (status 1 = failure, no output).
  "@drush -y status --field=drupal-version # 1"

  # Mock command with exit status 0 (success) and output "success".
  "@drush -y status --fields=bootstrap # 0 # success"

  # Mock command with exit status 1 (failure) and output "failure".
  "@drush -y status --fields=bootstrap # 1 # failure"

  # Mock command with exit status, output, AND side effect.
  # Side effect creates a file when the mock is called.
  "@drush cache-rebuild # 0 # Rebuilt # touch ${BATS_TEST_TMPDIR}/done"

  # Mock command with wildcard (*) - accepts any arguments.
  "@git * # 0 # Git operation successful"

  # Escaped hash: use \# for a literal # in arguments.
  "@curl https://example.com/page\#anchor # 0 # Response body"

  # Assert that the output contains the substring "Hello world".
  "Hello world"

  # Assert that the output does NOT contain the substring "Goodbye world".
  # The leading "- " indicates negation.
  "- Goodbye world"
)

# Setup phase: creates mocks and returns references to them.
mocks="$(steps_run "setup")"

# Run the code under test.
run ./my-script.sh

# Assert phase: verifies mocks were called correctly and output assertions pass.
steps_run "assert" "${mocks}"
```

#### Step types

A step can be one of the following types:

- [Command](#command) - mock a command
- [Substring presence](#substring-presence) - assert output contains string
- [Substring absence](#substring-absence) - assert output does NOT contain string
- [Expected call](#expected-call) - assert the ordered sequence of mocked calls

##### Command

`@<command> [<args>|*] # <mock_status> [ # <mock_output> [ # <mock_side_effect> ]]`

Mock a command with the given status, optional output, and optional side effect.

- `<command>` - the command to mock:
  - Steps for the same command can be mocked multiple times
  - Calls to the same command will use the same mock
- `<args>` - arguments to match (optional):
  - Match is exact
  - Use `*` as wildcard to accept any arguments
- `<mock_status>` - exit status to return (optional):
  - If not specified, `0` exit code will be used
  - Can be omitted if only `<mock_output>` is needed
- `<mock_output>` - output to return (optional)
- `<mock_side_effect>` - Bash code executed when mock is called (optional):
  - Useful for creating files/directories, setting env vars, logging, simulating complex behaviors
  - Executed in the context of the mock, not the test
  - Runs after output is generated but before exit status is returned
  - Chain multiple commands with `;` or `&&`
  - Use `${BATS_TEST_TMPDIR}` for temporary files
  - Each invocation of the same command can have different side effects

A step may contain at most three `#` characters and no consecutive `##`. Escape a literal `#` in the arguments as `\#`.

##### Substring presence

`<substring>`

Assert that the output contains the given substring.

##### Substring absence

`- <substring>`

Assert that the output does not contain the specified substring. Starts with `- ` (minus followed by a space).

##### Expected call

`= <call>`

Add a call to the expected sequence. Starts with `= ` (equals followed by a space), and the call is written in the serialisation the [call log](#call-log) documents. All such steps together are the complete ordered sequence of mocked calls, asserted once during the assert phase.

A `@` step orders the calls of one command; these steps order the calls of every command against each other:

```bash
declare -a STEPS=(
  "@git clone https://example.com/repo.git # 0"
  "@curl -s https://example.com/hook # 0"
  "@git checkout main # 0"

  "= git 'clone' 'https://example.com/repo.git'"
  "= curl '-s' 'https://example.com/hook'"
  "= git 'checkout' 'main'"
)

mocks="$(steps_run "setup")"
run ./deploy.sh
steps_run "assert" "${mocks}"
```

The assert phase also verifies the expectations of every mock it created, so a command called more times than the steps declare fails the run, and a declared step that is never consumed fails it too.

##### Debugging

Set `BATS_HELPERS_STEPS_DEBUG` to `1` to print the parsing and matching decisions of every step to file descriptor 3:

```bash
export BATS_HELPERS_STEPS_DEBUG=1
```

### Helpers

| Function Name             | Description                                                                   |
|---------------------------|-------------------------------------------------------------------------------|
| `file_mktouch`            | Creates a file and any missing parent directories                             |
| `file_trim`               | Removes the last line of a file in place                                      |
| `file_read_env`           | Evaluates an expression with the variables from the `./.env` file in scope    |
| `file_backup_path`        | Resolves the backup location of a file                                        |
| `file_add_var`            | Appends a variable assignment to a file, backing the file up first            |
| `file_restore`            | Restores a file from the backup taken by `file_add_var`                       |
| `fixture_prepare_dir`     | Creates an empty directory for a fixture, removing any existing content       |
| `fixture_export_codebase` | Exports the codebase at the latest commit to a destination directory          |
| `string_random`           | Generates a random alphanumeric string, 8 characters long by default          |
| `string_match`            | Reports whether a needle matches a haystack, without asserting on it          |
| `string_format_to_regex`  | Translates a format string into an extended regular expression                |
| `tui_run`                 | Runs the script named by `SCRIPT_FILE`, feeding it a list of answers on STDIN |
| `flunk`                   | Fails the test with a message                                                 |
| `format_error`            | Formats an error message with a border and the captured output and STDERR     |

`fixture_export_codebase` is a no-op unless `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` is set to `1`, so an expensive export can be enabled per suite rather than per call:

```bash
export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
```

#### Failure reporting

Helpers report a failure by writing a message to STDERR and returning a non-zero status. None of them call `exit`, so the caller stays in control and can compose them with `||`, branch on them with `if`, or capture the status with `run`:

```bash
# Recover from a failure and carry on.
fixture_export_codebase "${build_dir}" \
  || echo "Export failed - continuing without a codebase."

# Capture the status and the message.
run tui_run "${answers[@]}"
assert_failure
assert_output_contains "SCRIPT_FILE is not set."
```

A bare call still fails the test at that point, because BATS runs tests with `errexit` enabled.

#### File backups

`file_add_var` backs a file up before modifying it and `file_restore` puts that backup back. Backups are written below `${BATS_TEST_TMPDIR}/bats-helpers-backup`, mirroring the source path, so BATS removes them together with the rest of the test sandbox and concurrent runs cannot overwrite each other's backups.

Set `BATS_HELPERS_BACKUP_DIR` to store them elsewhere. Only the default location carries the guarantees above - a directory outside `${BATS_TEST_TMPDIR}` is not removed by BATS and is shared with concurrent runs:

```bash
export BATS_HELPERS_BACKUP_DIR="${BATS_TEST_TMPDIR}/backups"
```

Use `file_backup_path` to resolve where a given file's backup is stored:

```bash
assert_file_exists "$(file_backup_path "${BATS_TEST_TMPDIR}/.env")"
```

### Environment variables

Every variable the library defines, in one place. Each is also covered by the section of the feature that uses it. Variables that belong to bats-core - `BATS_TEST_TMPDIR`, `BATS_TMPDIR`, `BATS_TEST_DIRNAME`, `BATS_VERBOSE_RUN` - are read but not owned here, and are documented by [bats-core](https://bats-core.readthedocs.io/).

`STEPS`, `TEST_CASES` and `SCRIPT_FILE` are the test data a consumer declares right above the call that reads it, so they stay short and unprefixed. Everything the library reads from the wider environment carries the `BATS_HELPERS_` prefix.

| Variable                                       | Read by                                                       | Description                                                                                 |
|------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `STEPS`                                        | `steps_run`                                                   | Array of steps to process                                                                   |
| `TEST_CASES`                                   | `dataprovider_run`                                            | Array of test cases, each row ending with its expected value                                |
| `SCRIPT_FILE`                                  | `tui_run`                                                     | Path to the script to run, relative to the current directory                                |
| `BATS_HELPERS_STEPS_DEBUG`                     | `steps_run`                                                   | Set to `1` to print every parsing and matching decision to file descriptor 3                |
| `BATS_HELPERS_ASSERT_DIR_EXCLUDE`              | `assert_dir_contains_string`, `assert_dir_not_contains_string` | Array of directory names to exclude from the search, on top of the always-excluded four     |
| `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `fixture_export_codebase`                                     | Set to `1` to enable the export; anything else makes the function a no-op                   |
| `BATS_HELPERS_BACKUP_DIR`                      | `file_add_var`, `file_restore`, `file_backup_path`            | Backup root. Defaults to `${BATS_TEST_TMPDIR}/bats-helpers-backup`                          |
| `BATS_HELPERS_MOCK_TMPDIR`                     | `mock_setup`, `mock_create`                                   | Directory the mocks are written below. Defaults to `${BATS_TEST_TMPDIR}`, and `mock_setup` exports the resolved path |
| `BATS_HELPERS_MOCK_USER`                       | `mock_get_call_user`                                          | User a mock call is reported as. Defaults to `id -un`                                       |
| `BATS_HELPERS_MOCK_STRICT`                     | `mock_create`                                                 | Set to `0` to answer the calls a mock's expectations do not cover. Defaults to `1`, and is read when the mock is created |
| `BATS_HELPERS_DEPRECATION_QUIET`               | every module                                                  | Set to any non-empty value to silence every deprecation notice                              |

### Deprecations

These names still work, but print a notice on every call and are removed in the next version:

| Deprecated                       | Use instead                   |
|----------------------------------|-------------------------------|
| `assert_not_git_repo`            | `assert_git_not_repo`         |
| `assert_git_file_is_tracked`     | `assert_git_file_tracked`     |
| `assert_git_file_is_not_tracked` | `assert_git_file_not_tracked` |
| `assert_contains`                | `assert_string_contains`      |
| `assert_not_contains`            | `assert_string_not_contains`  |
| `run_steps`                      | `steps_run`                   |
| `setup_mock`                     | `mock_setup`                  |
| `mktouch`                        | `file_mktouch`                |
| `trim_file`                      | `file_trim`                   |
| `read_env`                       | `file_read_env`               |
| `add_var_to_file`                | `file_add_var`                |
| `restore_file`                   | `file_restore`                |
| `random_string`                  | `string_random`               |

The variables follow the same pattern. The old name is read only when the new one is unset or empty, so setting both to real values leaves the new one in charge:

| Deprecated                             | Use instead                                    |
|----------------------------------------|------------------------------------------------|
| `RUN_STEPS_DEBUG`                      | `BATS_HELPERS_STEPS_DEBUG`                     |
| `ASSERT_DIR_EXCLUDE`                   | `BATS_HELPERS_ASSERT_DIR_EXCLUDE`              |
| `BATS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` |
| `BATS_MOCK_TMPDIR`                     | `BATS_HELPERS_MOCK_TMPDIR`                     |
| `_USER`                                | `BATS_HELPERS_MOCK_USER`                       |

`mock_setup` now exports `BATS_HELPERS_MOCK_TMPDIR` rather than `BATS_MOCK_TMPDIR`. The old name is still read as an input, but it is no longer written, so a test that reads the mock directory back after `mock_setup` has to read the new name. `mock_resolve_tmp` also names the new variable when it cannot resolve a directory, so a test asserting on `Set BATS_MOCK_TMPDIR to a writable directory` has to be updated.

Every helper in a module shares one prefix - `steps_*`, `mock_*`, `file_*`, `string_*` - matching how bats-core namespaces `bats_*` and bats-support namespaces `batslib_*`. Apart from the two below, each replacement keeps the arguments, the standard output and the return semantics, so a call is updated by swapping the name alone.

`assert_contains` and `assert_not_contains` take the needle first, while their replacements take the haystack first, so a call has to swap its arguments as well as change its name:

```bash
assert_contains "needle" "some needle in a haystack"

assert_string_contains "some needle in a haystack" "needle"
```

The notice is written to file descriptor 3, so it shows up in the BATS output without being captured by `run` or by command substitution:

```text
Deprecated: 'assert_not_git_repo' will be removed in the next version. Use 'assert_git_not_repo' instead.
```

Set `BATS_HELPERS_DEPRECATION_QUIET` to any non-empty value to silence every notice:

```bash
export BATS_HELPERS_DEPRECATION_QUIET=1
```

## 🙏 Acknowledgments

The mocking functionality is based on the [bats-mock](https://github.com/grayhemp/bats-mock) project. A special thank you to the contributors for their original work.

## 🤝 Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for local development setup, the linting and testing commands, and the release procedure.

---
_This repository was created using the [Scaffold](https://getscaffold.dev/) project template_
