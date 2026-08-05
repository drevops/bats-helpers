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
- [Documentation](#-documentation)
- [API reference](#-api-reference)
- [Contributing](#-contributing)

## ✨ Features

- Assertions for command output, its individual lines, exit status, standard error, strings, files, directories and git repositories.
- Literal, regular expression and format matching, with case sensitivity as an explicit choice.
- Command mocking with per-call output, exit status and side effects, and responses selected by matched arguments.
- An ordered log of every mocked call, asserted as a sequence and reported as a unified diff.
- Mock expectations that fail the test when they go unused or when an unanticipated call arrives.
- An opt-in sandbox mode where an unmocked command is denied by name, with an allow-list for the commands that must run for real and a report of everything that left the mock boundary.
- Step runner for sequences of mocked calls and output assertions.
- Deferred cleanup registered next to the code that created the thing it removes.
- Retry for anything asynchronous, bounded by an attempt count, a delay and an optional deadline.
- Data provider for running one function over many test cases, with named cases, per-case arity, a chosen assertion and matrix expansion.
- Fixture and file utilities for building and restoring test sandboxes.
- A plain-text archive for declaring a whole fixture file tree inline in the test, serialising a directory back to it, and asserting a directory against it with per-file diffs.
- TUI helper for driving interactive scripts with scripted answers, bounded by a deadline and asserted against the prompts the script printed.

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

## 📖 Documentation

Most pages document one module of the library. The last three cut across modules: match modes are shared by every assertion family, and the variable and deprecation references cover the library as a whole. The [API reference](#-api-reference) below links every function into the page that documents it.

| Page                                              | Source                                                  | Covers                                                               |
|---------------------------------------------------|---------------------------------------------------------|----------------------------------------------------------------------|
| [Command assertions](docs/assertions-command.md)  | [`src/assert.command.bash`](src/assert.command.bash)    | Output, exit statuses and standard error of a command run with `run` |
| [Line assertions](docs/assertions-line.md)        | [`src/assert.line.bash`](src/assert.line.bash)          | Individual lines of a captured stream, by index, by any line and by count |
| [String assertions](docs/assertions-string.md)    | [`src/assert.string.bash`](src/assert.string.bash)      | Plain strings, and the string utilities behind the assertions        |
| [File assertions](docs/assertions-file.md)        | [`src/assert.file.bash`](src/assert.file.bash)          | Files, directories and symbolic links                                |
| [Git assertions](docs/assertions-git.md)          | [`src/assert.git.bash`](src/assert.git.bash)            | Git repositories and the files they track                            |
| [Match modes](docs/match-modes.md)                | [`src/assert.string.bash`](src/assert.string.bash)      | How a needle is read, and whether case matters                       |
| [Failure reporting](docs/failure-reporting.md)    | [`src/assert.base.bash`](src/assert.base.bash)          | The shape of every failure report, and how to raise one              |
| [Mocking](docs/mocking.md)                        | [`src/mock.bash`](src/mock.bash)                        | Command mocking, the call log, argument specifications, strictness and sandbox mode |
| [Step runner](docs/steps.md)                      | [`src/steps.bash`](src/steps.bash)                      | Sequences of mocked calls and output assertions                      |
| [Data provider](docs/dataprovider.md)             | [`src/dataprovider.bash`](src/dataprovider.bash)        | Running one function over many test cases                            |
| [Interactive scripts](docs/tui.md)                | [`src/tui.bash`](src/tui.bash)                          | Driving a script that asks questions                                 |
| [Retry](docs/retry.md)                            | [`src/retry.bash`](src/retry.bash)                      | Conditions that become true shortly                                  |
| [Cleanup](docs/cleanup.md)                        | [`src/cleanup.bash`](src/cleanup.bash)                  | Deferred per-test cleanup                                            |
| [Fixtures](docs/fixtures.md)                      | [`src/fixture.bash`](src/fixture.bash)                  | Building, dumping and asserting file trees                           |
| [File utilities](docs/files.md)                   | [`src/file.bash`](src/file.bash)                        | Creating, trimming, backing up and restoring files                   |
| [Environment variables](docs/environment-variables.md) | Every module                                       | Every variable the library reads or writes                           |
| [Deprecations](docs/deprecations.md)              | Every module                                            | Renamed functions, variables and arguments                           |

## 🧩 API reference

Every public function, the file that defines it, and the page that documents it. Functions whose names start with an underscore are internal, are not part of the public API, and may change or disappear in any release without notice.

| Function | Source | Description | Documentation |
|----------|--------|-------------|---------------|
| `flunk` | [assert.base.bash](src/assert.base.bash) | Fails the test with a message, its stack trace and stable paths | [Failure reporting](docs/failure-reporting.md#failure-reporting) |
| `format_error` | [assert.base.bash](src/assert.base.bash) | Formats a failure report as a titled block of aligned rows | [Failure reporting](docs/failure-reporting.md#failure-reporting) |
| `assert_empty` | [assert.string.bash](src/assert.string.bash) | Asserts that a string is empty | [String assertions](docs/assertions-string.md#assertions) |
| `assert_not_empty` | [assert.string.bash](src/assert.string.bash) | Asserts that a string is not empty | [String assertions](docs/assertions-string.md#assertions) |
| `assert_equal` | [assert.string.bash](src/assert.string.bash) | Asserts that two strings are equal | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_contains` | [assert.string.bash](src/assert.string.bash) | Asserts that a string contains a substring | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_contains_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string contains a substring, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_contains` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not contain a substring | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_contains_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not contain a substring, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_starts_with` | [assert.string.bash](src/assert.string.bash) | Asserts that a string starts with a substring | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_starts_with_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string starts with a substring, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_starts_with` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not start with a substring | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_starts_with_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not start with a substring, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_ends_with` | [assert.string.bash](src/assert.string.bash) | Asserts that a string ends with a substring | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_ends_with_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string ends with a substring, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_ends_with` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not end with a substring | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_ends_with_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not end with a substring, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_matches` | [assert.string.bash](src/assert.string.bash) | Asserts that a string matches a regular expression | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_matches_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string matches a regular expression, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_matches` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not match a regular expression | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_matches_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not match a regular expression, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_matches_format` | [assert.string.bash](src/assert.string.bash) | Asserts that a string matches a format string | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_matches_format_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string matches a format string, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_matches_format` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not match a format string | [String assertions](docs/assertions-string.md#assertions) |
| `assert_string_not_matches_format_case` | [assert.string.bash](src/assert.string.bash) | Asserts that a string does not match a format string, case-sensitively | [String assertions](docs/assertions-string.md#assertions) |
| `string_match` | [assert.string.bash](src/assert.string.bash) | Reports whether a needle matches a haystack, without asserting on it | [String utilities](docs/assertions-string.md#string-utilities) |
| `string_format_to_regex` | [assert.string.bash](src/assert.string.bash) | Translates a format string into an extended regular expression | [String utilities](docs/assertions-string.md#string-utilities) |
| `string_random` | [assert.string.bash](src/assert.string.bash) | Generates a random alphanumeric string, 8 characters long by default | [String utilities](docs/assertions-string.md#string-utilities) |
| `assert_success` | [assert.command.bash](src/assert.command.bash) | Asserts that a command succeeds | [Command assertions](docs/assertions-command.md#output) |
| `assert_failure` | [assert.command.bash](src/assert.command.bash) | Asserts that a command fails | [Command assertions](docs/assertions-command.md#output) |
| `assert_output` | [assert.command.bash](src/assert.command.bash) | Asserts that a command outputs an exact string | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_contains` | [assert.command.bash](src/assert.command.bash) | Asserts that output contains a substring | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_contains_case` | [assert.command.bash](src/assert.command.bash) | Asserts that output contains a substring, case-sensitively | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_not_contains` | [assert.command.bash](src/assert.command.bash) | Asserts that output does not contain a substring | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_not_contains_case` | [assert.command.bash](src/assert.command.bash) | Asserts that output does not contain a substring, case-sensitively | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_matches` | [assert.command.bash](src/assert.command.bash) | Asserts that output matches a regular expression | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_matches_case` | [assert.command.bash](src/assert.command.bash) | Asserts that output matches a regular expression, case-sensitively | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_not_matches` | [assert.command.bash](src/assert.command.bash) | Asserts that output does not match a regular expression | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_not_matches_case` | [assert.command.bash](src/assert.command.bash) | Asserts that output does not match a regular expression, case-sensitively | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_matches_format` | [assert.command.bash](src/assert.command.bash) | Asserts that output matches a format string | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_matches_format_case` | [assert.command.bash](src/assert.command.bash) | Asserts that output matches a format string, case-sensitively | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_not_matches_format` | [assert.command.bash](src/assert.command.bash) | Asserts that output does not match a format string | [Command assertions](docs/assertions-command.md#output) |
| `assert_output_not_matches_format_case` | [assert.command.bash](src/assert.command.bash) | Asserts that output does not match a format string, case-sensitively | [Command assertions](docs/assertions-command.md#output) |
| `assert_status` | [assert.command.bash](src/assert.command.bash) | Asserts that a command exits with an exact status | [Exit statuses](docs/assertions-command.md#exit-statuses) |
| `assert_failure_status` | [assert.command.bash](src/assert.command.bash) | Asserts that a command fails with an exact status | [Exit statuses](docs/assertions-command.md#exit-statuses) |
| `assert_status_general_error` | [assert.command.bash](src/assert.command.bash) | Asserts that a command exits with status `1` | [Exit statuses](docs/assertions-command.md#exit-statuses) |
| `assert_status_command_not_found` | [assert.command.bash](src/assert.command.bash) | Asserts that a command exits with status `127` | [Exit statuses](docs/assertions-command.md#exit-statuses) |
| `assert_stderr` | [assert.command.bash](src/assert.command.bash) | Asserts that a command writes an exact string to STDERR | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_empty` | [assert.command.bash](src/assert.command.bash) | Asserts that a command wrote nothing to STDERR | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_captured` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR was captured separately from the output | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_contains` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR contains a substring | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_contains_case` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR contains a substring, case-sensitively | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_not_contains` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR does not contain a substring | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_not_contains_case` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR does not contain a substring, case-sensitively | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_matches` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR matches a regular expression | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_matches_case` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR matches a regular expression, case-sensitively | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_not_matches` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR does not match a regular expression | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_not_matches_case` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR does not match a regular expression, case-sensitively | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_matches_format` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR matches a format string | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_matches_format_case` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR matches a format string, case-sensitively | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_not_matches_format` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR does not match a format string | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_stderr_not_matches_format_case` | [assert.command.bash](src/assert.command.bash) | Asserts that STDERR does not match a format string, case-sensitively | [Standard error](docs/assertions-command.md#standard-error) |
| `assert_line` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index equals a string | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not equal a string | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_contains` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index contains a string | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_contains_case` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index contains a string, case-sensitively | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not_contains` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not contain a string | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not_contains_case` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not contain a string, case-sensitively | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_matches` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index matches a regular expression | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_matches_case` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index matches a regular expression, case-sensitively | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not_matches` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not match a regular expression | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not_matches_case` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not match a regular expression, case-sensitively | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_matches_format` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index matches a format string | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_matches_format_case` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index matches a format string, case-sensitively | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not_matches_format` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not match a format string | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_line_not_matches_format_case` | [assert.line.bash](src/assert.line.bash) | Asserts that the line at an index does not match a format string, case-sensitively | [Line assertions](docs/assertions-line.md#by-index) |
| `assert_any_line` | [assert.line.bash](src/assert.line.bash) | Asserts that some line equals a string | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line` | [assert.line.bash](src/assert.line.bash) | Asserts that no line equals a string | [Any line](docs/assertions-line.md#any-line) |
| `assert_any_line_contains` | [assert.line.bash](src/assert.line.bash) | Asserts that some line contains a string | [Any line](docs/assertions-line.md#any-line) |
| `assert_any_line_contains_case` | [assert.line.bash](src/assert.line.bash) | Asserts that some line contains a string, case-sensitively | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line_contains` | [assert.line.bash](src/assert.line.bash) | Asserts that no line contains a string | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line_contains_case` | [assert.line.bash](src/assert.line.bash) | Asserts that no line contains a string, case-sensitively | [Any line](docs/assertions-line.md#any-line) |
| `assert_any_line_matches` | [assert.line.bash](src/assert.line.bash) | Asserts that some line matches a regular expression | [Any line](docs/assertions-line.md#any-line) |
| `assert_any_line_matches_case` | [assert.line.bash](src/assert.line.bash) | Asserts that some line matches a regular expression, case-sensitively | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line_matches` | [assert.line.bash](src/assert.line.bash) | Asserts that no line matches a regular expression | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line_matches_case` | [assert.line.bash](src/assert.line.bash) | Asserts that no line matches a regular expression, case-sensitively | [Any line](docs/assertions-line.md#any-line) |
| `assert_any_line_matches_format` | [assert.line.bash](src/assert.line.bash) | Asserts that some line matches a format string | [Any line](docs/assertions-line.md#any-line) |
| `assert_any_line_matches_format_case` | [assert.line.bash](src/assert.line.bash) | Asserts that some line matches a format string, case-sensitively | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line_matches_format` | [assert.line.bash](src/assert.line.bash) | Asserts that no line matches a format string | [Any line](docs/assertions-line.md#any-line) |
| `assert_no_line_matches_format_case` | [assert.line.bash](src/assert.line.bash) | Asserts that no line matches a format string, case-sensitively | [Any line](docs/assertions-line.md#any-line) |
| `assert_line_count` | [assert.line.bash](src/assert.line.bash) | Asserts the number of lines | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not` | [assert.line.bash](src/assert.line.bash) | Asserts that the number of lines differs | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_contains` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines contain a string | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_contains_case` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines contain a string, case-sensitively | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not_contains` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines do not contain a string | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not_contains_case` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines do not contain a string, case-sensitively | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_matches` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines match a regular expression | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_matches_case` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines match a regular expression, case-sensitively | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not_matches` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines do not match a regular expression | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not_matches_case` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines do not match a regular expression, case-sensitively | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_matches_format` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines match a format string | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_matches_format_case` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines match a format string, case-sensitively | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not_matches_format` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines do not match a format string | [Counts](docs/assertions-line.md#counts) |
| `assert_line_count_not_matches_format_case` | [assert.line.bash](src/assert.line.bash) | Asserts how many lines do not match a format string, case-sensitively | [Counts](docs/assertions-line.md#counts) |
| `assert_file_exists` | [assert.file.bash](src/assert.file.bash) | Asserts that a file exists | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_exists` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not exist | [File assertions](docs/assertions-file.md#files) |
| `assert_file_contains` | [assert.file.bash](src/assert.file.bash) | Asserts that a file contains a string | [File assertions](docs/assertions-file.md#files) |
| `assert_file_contains_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file contains a string, case-sensitively | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_contains` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not contain a string | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_contains_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not contain a string, case-sensitively | [File assertions](docs/assertions-file.md#files) |
| `assert_file_matches` | [assert.file.bash](src/assert.file.bash) | Asserts that a file matches a regular expression | [File assertions](docs/assertions-file.md#files) |
| `assert_file_matches_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file matches a regular expression, case-sensitively | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_matches` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not match a regular expression | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_matches_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not match a regular expression, case-sensitively | [File assertions](docs/assertions-file.md#files) |
| `assert_file_matches_format` | [assert.file.bash](src/assert.file.bash) | Asserts that a file matches a format string | [File assertions](docs/assertions-file.md#files) |
| `assert_file_matches_format_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file matches a format string, case-sensitively | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_matches_format` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not match a format string | [File assertions](docs/assertions-file.md#files) |
| `assert_file_not_matches_format_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file does not match a format string, case-sensitively | [File assertions](docs/assertions-file.md#files) |
| `assert_files_equal` | [assert.file.bash](src/assert.file.bash) | Asserts that two files are equal | [File assertions](docs/assertions-file.md#comparing-files) |
| `assert_files_equal_ignore_spaces` | [assert.file.bash](src/assert.file.bash) | Asserts that two files are equal, ignoring blank lines and whitespace changes | [File assertions](docs/assertions-file.md#comparing-files) |
| `assert_files_not_equal` | [assert.file.bash](src/assert.file.bash) | Asserts that two files are not equal | [File assertions](docs/assertions-file.md#comparing-files) |
| `assert_files_not_equal_ignore_spaces` | [assert.file.bash](src/assert.file.bash) | Asserts that two files are not equal, ignoring blank lines and whitespace changes | [File assertions](docs/assertions-file.md#comparing-files) |
| `assert_binary_files_equal` | [assert.file.bash](src/assert.file.bash) | Asserts that two binary files are equal | [File assertions](docs/assertions-file.md#files) |
| `assert_binary_files_not_equal` | [assert.file.bash](src/assert.file.bash) | Asserts that two binary files are not equal | [File assertions](docs/assertions-file.md#files) |
| `assert_file_mode` | [assert.file.bash](src/assert.file.bash) | Asserts the file permission mode | [File assertions](docs/assertions-file.md#files) |
| `assert_dir_exists` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory exists | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_dir_not_exists` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory does not exist | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_dir_empty` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory is empty | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_dir_not_empty` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory is not empty | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_dir_contains_string` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory contains a string in one of its files | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_contains_string_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory contains a string in one of its files, case-sensitively | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_not_contains_string` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory does not contain a string in any of its files | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_not_contains_string_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a directory does not contain a string in any of its files, case-sensitively | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_matches` | [assert.file.bash](src/assert.file.bash) | Asserts that a file of a directory matches a regular expression | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_matches_case` | [assert.file.bash](src/assert.file.bash) | Asserts that a file of a directory matches a regular expression, case-sensitively | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_not_matches` | [assert.file.bash](src/assert.file.bash) | Asserts that no file of a directory matches a regular expression | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dir_not_matches_case` | [assert.file.bash](src/assert.file.bash) | Asserts that no file of a directory matches a regular expression, case-sensitively | [Searching a directory](docs/assertions-file.md#searching-a-directory) |
| `assert_dirs_equal` | [assert.file.bash](src/assert.file.bash) | Asserts that two directories are equal | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_symlink_exists` | [assert.file.bash](src/assert.file.bash) | Asserts that a symbolic link exists | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_symlink_not_exists` | [assert.file.bash](src/assert.file.bash) | Asserts that a symbolic link does not exist | [Directories and symlinks](docs/assertions-file.md#directories-and-symlinks) |
| `assert_git_repo` | [assert.git.bash](src/assert.git.bash) | Asserts that a directory is a git repository | [Git assertions](docs/assertions-git.md#git-assertions) |
| `assert_git_not_repo` | [assert.git.bash](src/assert.git.bash) | Asserts that a directory is not a git repository | [Git assertions](docs/assertions-git.md#git-assertions) |
| `assert_git_clean` | [assert.git.bash](src/assert.git.bash) | Asserts that a git repository is clean | [Git assertions](docs/assertions-git.md#git-assertions) |
| `assert_git_not_clean` | [assert.git.bash](src/assert.git.bash) | Asserts that a git repository is not clean | [Git assertions](docs/assertions-git.md#git-assertions) |
| `assert_git_file_tracked` | [assert.git.bash](src/assert.git.bash) | Asserts that a file is tracked in git | [Git assertions](docs/assertions-git.md#git-assertions) |
| `assert_git_file_not_tracked` | [assert.git.bash](src/assert.git.bash) | Asserts that a file is not tracked in git | [Git assertions](docs/assertions-git.md#git-assertions) |
| `cleanup_register` | [cleanup.bash](src/cleanup.bash) | Registers a command to run once the current test has finished | [Cleanup](docs/cleanup.md#cleanup) |
| `cleanup_run` | [cleanup.bash](src/cleanup.bash) | Runs the registered commands in reverse order. Call from `teardown()` | [Cleanup](docs/cleanup.md#composing-with-your-teardown) |
| `cleanup_registry_path` | [cleanup.bash](src/cleanup.bash) | Resolves the file the registry is stored in | [Cleanup sandbox](docs/cleanup.md#cleanup-sandbox) |
| `retry_run` | [retry.bash](src/retry.bash) | Runs a command until it succeeds or until a bound is reached | [Retry](docs/retry.md#retry) |
| `file_mktouch` | [file.bash](src/file.bash) | Creates a file and any missing parent directories | [File utilities](docs/files.md#file-utilities) |
| `file_trim` | [file.bash](src/file.bash) | Removes the last line of a file in place | [File utilities](docs/files.md#file-utilities) |
| `file_read_env` | [file.bash](src/file.bash) | Evaluates an expression with the variables from the `./.env` file in scope | [File utilities](docs/files.md#file-utilities) |
| `file_backup_path` | [file.bash](src/file.bash) | Resolves the backup location of a file | [File backups](docs/files.md#file-backups) |
| `file_add_var` | [file.bash](src/file.bash) | Appends a variable assignment to a file, backing the file up first | [File backups](docs/files.md#file-backups) |
| `file_restore` | [file.bash](src/file.bash) | Restores a file from the backup taken by `file_add_var` | [File backups](docs/files.md#file-backups) |
| `fixture_prepare_dir` | [fixture.bash](src/fixture.bash) | Creates an empty directory for a fixture, removing any existing content | [Fixtures](docs/fixtures.md#fixtures) |
| `fixture_export_codebase` | [fixture.bash](src/fixture.bash) | Exports the codebase at the latest commit to a destination directory | [Fixtures](docs/fixtures.md#fixtures) |
| `fixture_create_dir` | [fixture.bash](src/fixture.bash) | Creates a file tree from an archive read from STDIN | [Fixture trees](docs/fixtures.md#fixture-trees) |
| `fixture_dump_dir` | [fixture.bash](src/fixture.bash) | Prints a directory as an archive | [Fixture trees](docs/fixtures.md#fixture-trees) |
| `fixture_assert_dir` | [fixture.bash](src/fixture.bash) | Asserts that a directory holds the file tree of an archive read from STDIN | [Fixture trees](docs/fixtures.md#fixture-trees) |
| `dataprovider_run` | [dataprovider.bash](src/dataprovider.bash) | Runs the cases held in the `TEST_CASES` array | [Flat array](docs/dataprovider.md#flat-array) |
| `dataprovider_run_cases` | [dataprovider.bash](src/dataprovider.bash) | Runs the cases that a function declares | [Declared cases](docs/dataprovider.md#declared-cases) |
| `dataprovider_case` | [dataprovider.bash](src/dataprovider.bash) | Declares and runs one case | [Declared cases](docs/dataprovider.md#declared-cases) |
| `dataprovider_matrix` | [dataprovider.bash](src/dataprovider.bash) | Expands value lists into their cartesian product | [Matrix](docs/dataprovider.md#matrix) |
| `mock_setup` | [mock.bash](src/mock.bash) | Sets mocking up. Call from `setup()` | [Setup functions](docs/mocking.md#setup-functions) |
| `mock_create` | [mock.bash](src/mock.bash) | Creates a mock program that can be tracked | [Setup functions](docs/mocking.md#setup-functions) |
| `mock_command` | [mock.bash](src/mock.bash) | Mocks the provided command | [Setup functions](docs/mocking.md#setup-functions) |
| `mock_set_output` | [mock.bash](src/mock.bash) | Sets the output of the mock | [Setup functions](docs/mocking.md#setup-functions) |
| `mock_set_status` | [mock.bash](src/mock.bash) | Sets the exit status of the mock | [Setup functions](docs/mocking.md#setup-functions) |
| `mock_set_side_effect` | [mock.bash](src/mock.bash) | Sets shell code to run when the mock executes | [Setup functions](docs/mocking.md#setup-functions) |
| `mock_set_strict` | [mock.bash](src/mock.bash) | Rejects the calls the mock's expectations do not cover | [Strictness](docs/mocking.md#strictness) |
| `mock_set_forward` | [mock.bash](src/mock.bash) | Runs the real command for calls no specification accepts | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_spec_add` | [mock.bash](src/mock.bash) | Adds an argument specification to the mock | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_spec_arg` | [mock.bash](src/mock.bash) | Constrains one argument position of a specification | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_spec_count` | [mock.bash](src/mock.bash) | Pins the number of arguments a specification accepts | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_spec_set_output` | [mock.bash](src/mock.bash) | Sets the output a specification responds with | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_spec_set_status` | [mock.bash](src/mock.bash) | Sets the exit status a specification responds with | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_spec_set_side_effect` | [mock.bash](src/mock.bash) | Sets shell code a specification runs | [Argument specifications](docs/mocking.md#argument-specifications) |
| `mock_log_exclude` | [mock.bash](src/mock.bash) | Excludes commands from sequence comparisons | [Call log](docs/mocking.md#call-log) |
| `mock_log_print` | [mock.bash](src/mock.bash) | Returns every recorded call, in order | [Call log](docs/mocking.md#call-log) |
| `mock_get_call_num` | [mock.bash](src/mock.bash) | Returns the number of times the mock was called | [Assertion functions](docs/mocking.md#assertion-functions) |
| `mock_get_call_args` | [mock.bash](src/mock.bash) | Returns the arguments the mock was called with | [Assertion functions](docs/mocking.md#assertion-functions) |
| `mock_get_call_user` | [mock.bash](src/mock.bash) | Returns the user the mock was called with | [Assertion functions](docs/mocking.md#assertion-functions) |
| `mock_get_call_env` | [mock.bash](src/mock.bash) | Returns an environment variable value from a mock call | [Assertion functions](docs/mocking.md#assertion-functions) |
| `mock_assert_call_args` | [mock.bash](src/mock.bash) | Asserts the arguments the mock was called with | [Assertion functions](docs/mocking.md#assertion-functions) |
| `mock_assert_calls` | [mock.bash](src/mock.bash) | Asserts the ordered sequence of every mocked call | [Call log](docs/mocking.md#call-log) |
| `mock_assert_no_calls` | [mock.bash](src/mock.bash) | Asserts that no mocked command outside the excluded ones was called | [Call log](docs/mocking.md#call-log) |
| `mock_assert_called` | [mock.bash](src/mock.bash) | Asserts that a command was called | [Call log](docs/mocking.md#call-log) |
| `mock_assert_not_called` | [mock.bash](src/mock.bash) | Asserts that a command was not called | [Call log](docs/mocking.md#call-log) |
| `mock_verify` | [mock.bash](src/mock.bash) | Asserts that every expectation was met | [Strictness](docs/mocking.md#strictness) |
| `mock_sandbox_enable` | [mock.bash](src/mock.bash) | Enables sandbox mode. Arguments seed the allow-list | [Sandbox mode](docs/mocking.md#sandbox-mode) |
| `mock_sandbox_allow` | [mock.bash](src/mock.bash) | Allows commands to run for real | [Sandbox mode](docs/mocking.md#allowing-a-command-to-run-for-real) |
| `mock_sandbox_disable` | [mock.bash](src/mock.bash) | Restores the `PATH` saved when the mode was enabled | [Sandbox mode](docs/mocking.md#sandbox-mode) |
| `mock_sandbox_enabled` | [mock.bash](src/mock.bash) | Reports whether sandbox mode is enabled | [Sandbox mode](docs/mocking.md#sandbox-mode) |
| `mock_sandbox_report` | [mock.bash](src/mock.bash) | Prints the denied and the escaped commands | [What escaped](docs/mocking.md#what-escaped) |
| `mock_path_check` | [mock.bash](src/mock.bash) | Warns when `PATH` changed after `mock_setup` | [When PATH is rewritten](docs/mocking.md#when-path-is-rewritten) |
| `steps_run` | [steps.bash](src/steps.bash) | Runs the `setup` or the `assert` phase of the `STEPS` array | [Step runner](docs/steps.md#step-runner) |
| `tui_run` | [tui.bash](src/tui.bash) | Runs the script named by `SCRIPT_FILE`, feeding it answers on STDIN | [Interactive scripts](docs/tui.md#interactive-scripts) |
| `tui_assert_prompts` | [tui.bash](src/tui.bash) | Asserts the prompts appeared in order, ignoring case | [Prompt order](docs/tui.md#prompt-order) |
| `tui_assert_prompts_case` | [tui.bash](src/tui.bash) | Asserts the prompts appeared in order, case-sensitively | [Prompt order](docs/tui.md#prompt-order) |

Deprecated names are listed in [Deprecations](docs/deprecations.md) and in [`MIGRATION.md`](MIGRATION.md).

## 🤝 Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for local development setup, the linting and testing commands, and the release procedure.

---
_This repository was created using the [Scaffold](https://getscaffold.dev/) project template_
