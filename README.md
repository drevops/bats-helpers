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
  - [Assertions](#assertions) - Command run, String, File, Git
  - [Data provider](#data-provider) - Parameterized tests
  - [Mocking](#mocking) - Command mocking
  - [Step runner](#step-runner) - Sequential test assertions
  - [Helpers](#helpers) - Utility functions
  - [Environment variables](#environment-variables) - Full variable reference
  - [Deprecations](#deprecations) - Renamed functions and variables
- [Acknowledgments](#-acknowledgments)
- [Contributing](#-contributing)

## ✨ Features

- Assertions for command output, strings, files, directories and git repositories.
- Command mocking with per-call output, exit status and side effects.
- Step runner for sequences of mocked calls and output assertions.
- Data provider for running one function over many test cases.
- Fixture and file utilities for building and restoring test sandboxes.
- TUI helper for driving interactive scripts with scripted answers.

## 📦 Installation

Requires [bats-core](https://github.com/bats-core/bats-core) `1.10` or newer.

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

| Function Name                | Description                                         |
|------------------------------|-----------------------------------------------------|
| `assert_success`             | Asserts that a command succeeds                     |
| `assert_failure`             | Asserts that a command fails                        |
| `assert_output`              | Asserts that a command outputs an exact string      |
| `assert_output_contains`     | Checks if output contains a specific string         |
| `assert_output_not_contains` | Checks if output does not contain a specific string |

#### String assertions

| Function Name                | Description                                        |
|------------------------------|----------------------------------------------------|
| `assert_empty`               | Asserts that a string is empty                     |
| `assert_not_empty`           | Asserts that a string is not empty                 |
| `assert_equal`               | Asserts that two strings are equal                 |
| `assert_string_contains`     | Asserts that a string contains a given substring   |
| `assert_string_not_contains` | Asserts that a string does not contain a substring |

`assert_string_contains` and `assert_string_not_contains` match case-insensitively and treat the needle as a literal string. So do the assertions built on them: `assert_output_contains`, `assert_output_not_contains`, `assert_file_contains` and `assert_file_not_contains`.

Every `contains` assertion takes the container first and the string to look for second:

```bash
assert_string_contains "some needle in a haystack" "needle"
assert_file_contains "${file}" "needle"
assert_dir_contains_string "${dir}" "needle"
```

#### File assertions

| Function Name                    | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `assert_file_exists`             | Asserts that a file exists                             |
| `assert_file_not_exists`         | Asserts that a file does not exist                     |
| `assert_file_contains`           | Checks if a file contains a specific string            |
| `assert_file_not_contains`       | Checks if a file does not contain a specific string    |
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

`assert_file_exists` and `assert_file_not_exists` accept a glob. Only the first match decides the outcome, and the failure is reported once however many paths the glob expands to:

```bash
assert_file_exists "${dir}/*.txt"
assert_file_not_exists "${dir}/*.rtf"
```

`assert_dir_contains_string` and `assert_dir_not_contains_string` search recursively, skip binary files, and always exclude `.git`, `.idea`, `vendor` and `node_modules`. Unlike the string and file assertions, they match case-sensitively and read the string as a `grep` basic regular expression. Set `BATS_HELPERS_ASSERT_DIR_EXCLUDE` to an array of additional directory names to exclude:

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
2. `args_per_row`: (Optional) The number of arguments in each row of the `BATS_HELPERS_TEST_CASES` array, defaults to `1`. Last argument is always the expected value.

Global Variables:

- `BATS_HELPERS_TEST_CASES`: An array containing test cases with their expected values.

**Examples:**

To run a function `add_numbers` with `BATS_HELPERS_TEST_CASES` containing three arguments per row, you can call `dataprovider_run` like so:

```bash
# Function to test.
add_numbers() {
  echo "$(($1 + $2))"
}

@test "Test add_numbers" {
  # Numbers: first two are inputs, last is expected output.
  declare -a BATS_HELPERS_TEST_CASES=(
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

| Function               | Description                                | Arguments                        | Returns   |
|------------------------|--------------------------------------------|----------------------------------|-----------|
| `mock_setup`           | Setup mock support. Call from `setup()`    | None                             | None      |
| `mock_create`          | Creates a mock program that can be tracked | None                             | Mock path |
| `mock_command`         | Mock provided command                      | `command_name`                   | Mock path |
| `mock_set_output`      | Sets the output of the mock                | `mock`, `output`, `[call_index]` | None      |
| `mock_set_status`      | Sets the exit status of the mock           | `mock`, `status`, `[call_index]` | None      |
| `mock_set_side_effect` | Sets shell code to run when mock executes  | `mock`, `code`, `[call_index]`   | None      |

#### Assertion functions

| Function                | Description                                                                    | Arguments                               | Returns          |
|-------------------------|--------------------------------------------------------------------------------|-----------------------------------------|------------------|
| `mock_get_call_args`    | Returns arguments the mock was called with                                     | `mock`, `[call_index]`                  | Arguments string |
| `mock_get_call_num`     | Returns number of times mock was called                                        | `mock`                                  | Call count       |
| `mock_get_call_user`    | Returns user the mock was called with                                          | `mock`, `[call_index]`                  | User name        |
| `mock_get_call_env`     | Returns env variable value from mock call                                      | `mock`, `var_name`, `[call_index]`      | Variable value   |
| `mock_assert_call_args` | Checks the arguments the mock was called with, where `*` matches any arguments | `mock`, `expected_args`, `[call_index]` | `0` when matched |

#### Mock sandbox

`mock_setup` writes the mocks to `${BATS_TEST_TMPDIR}/bats-mock-tmp` and puts that directory first on `PATH`, so BATS removes the mocks together with the rest of the test sandbox and concurrent runs cannot delete each other's mocks.

Set `BATS_MOCK_TMPDIR` to store them elsewhere; the mocks are written to a `bats-mock-tmp` directory below it. The guarantees above come from staying within the test sandbox - a directory outside `${BATS_TEST_TMPDIR}` is not removed by BATS and is shared with concurrent runs:

```bash
export BATS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/mocks"
```

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
# Declare BATS_HELPERS_STEPS as a global variable, as `steps_run` needs to be
# called twice and it does not store the steps internally.
declare -a BATS_HELPERS_STEPS=(
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
| `tui_run`                 | Runs the script named by `BATS_HELPERS_SCRIPT_FILE`, feeding it answers on STDIN |
| `flunk`                   | Fails the test with a message                                                 |
| `format_error`            | Formats an error message with a border and the captured command output        |

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
assert_output_contains "BATS_HELPERS_SCRIPT_FILE is not set."
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

| Variable                                       | Read by                                                       | Description                                                                                 |
|------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `BATS_HELPERS_STEPS`                           | `steps_run`                                                   | Array of steps to process                                                                   |
| `BATS_HELPERS_STEPS_DEBUG`                     | `steps_run`                                                   | Set to `1` to print every parsing and matching decision to file descriptor 3                |
| `BATS_HELPERS_TEST_CASES`                      | `dataprovider_run`                                            | Array of test cases, each row ending with its expected value                                |
| `BATS_HELPERS_SCRIPT_FILE`                     | `tui_run`                                                     | Path to the script to run, relative to the current directory                                |
| `BATS_HELPERS_ASSERT_DIR_EXCLUDE`              | `assert_dir_contains_string`, `assert_dir_not_contains_string` | Array of directory names to exclude from the search, on top of the always-excluded four     |
| `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `fixture_export_codebase`                                     | Set to `1` to enable the export; anything else makes the function a no-op                   |
| `BATS_HELPERS_BACKUP_DIR`                      | `file_add_var`, `file_restore`, `file_backup_path`            | Backup root. Defaults to `${BATS_TEST_TMPDIR}/bats-helpers-backup`                          |
| `BATS_HELPERS_DEPRECATION_QUIET`               | every module                                                  | Set to any non-empty value to silence every deprecation notice                              |
| `BATS_MOCK_TMPDIR`                             | `mock_setup`, `mock_create`                                   | Directory the mocks are written below. Defaults to `${BATS_TEST_TMPDIR}`                    |

`BATS_MOCK_TMPDIR` is the one variable without the `BATS_HELPERS_` prefix. It is [bats-mock](https://github.com/grayhemp/bats-mock)'s own name, and `mock_setup` exports it for the test to read back, so it is both an input and an output.

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

The variables follow the same pattern. The old name is read only when the new one is unset, so setting both leaves the new one in charge:

| Deprecated                             | Use instead                                    |
|----------------------------------------|------------------------------------------------|
| `STEPS`                                | `BATS_HELPERS_STEPS`                           |
| `RUN_STEPS_DEBUG`                      | `BATS_HELPERS_STEPS_DEBUG`                     |
| `TEST_CASES`                           | `BATS_HELPERS_TEST_CASES`                      |
| `SCRIPT_FILE`                          | `BATS_HELPERS_SCRIPT_FILE`                     |
| `ASSERT_DIR_EXCLUDE`                   | `BATS_HELPERS_ASSERT_DIR_EXCLUDE`              |
| `BATS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` |

Failure messages name the new variable, so a test asserting on `TEST_CASES array is empty.` or `SCRIPT_FILE is not set.` has to be updated even while the old variable still works.

Every helper in a module shares one prefix - `steps_*`, `mock_*`, `file_*`, `string_*` - and every variable the library owns shares the `BATS_HELPERS_` prefix, matching how bats-core namespaces `bats_*` and bats-support namespaces `batslib_*`. Apart from the two below, each replacement keeps the arguments, the standard output and the return semantics, so a call is updated by swapping the name alone.

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
