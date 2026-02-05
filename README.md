<p align="center">
  <a href="https://bats-helpers.drevops.com" rel="noopener">
 <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=BATS%20helpers&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="Project logo"></a>
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

- [Installation](#installation)
- [Usage](#usage)
  - [Load library](#load-library)
  - [Assertions](#assertions) - Command run, String, File, Git
  - [Data Provider](#data-provider) - Parameterized tests
  - [Mocking](#mocking) - Command mocking
  - [Step Runner](#step-runner) - Sequential test assertions
  - [Helpers](#helpers) - Utility functions
- [Maintenance](#maintenance)

## Installation

### NPM

1. Install the library:
    ```shell
    npm install -D bats-helpers@npm:@drevops/bats-helpers
    ```
   This will also install `bats-core`.

2. Create a `_loader.bash` file next to your BATS tests with content:

   ```bash
   export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/../node_modules"
   bats_load_library bats-helpers
   ```

### From source

1. Click `Code` -> `Download ZIP` in
   the [GitHub UI](https://github.com/drevops/bats-helpers).
2. Extract files to a desired location. Usually, next to where `bats-core` is
   located.
3. Create a `_loader.bash` file next to your BATS tests with content:

   ```bash
   export BATS_LIB_PATH="<path/to/extracted/files>"
   bats_load_library bats-helpers
   ```

## Usage

### Load library

Use `load _loader.bash` in every BATS file:

```bats
#!/usr/bin/env bats
load _loader

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

| Function Name         | Description                                        |
|-----------------------|----------------------------------------------------|
| `assert_empty`        | Asserts that a string is empty                     |
| `assert_not_empty`    | Asserts that a string is not empty                 |
| `assert_equal`        | Asserts that two strings are equal                 |
| `assert_contains`     | Asserts that a string contains a given substring   |
| `assert_not_contains` | Asserts that a string does not contain a substring |

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

#### Git assertions

| Function Name                    | Description                                      |
|----------------------------------|--------------------------------------------------|
| `assert_git_repo`                | Asserts that a directory is a git repository     |
| `assert_not_git_repo`            | Asserts that a directory is not a git repository |
| `assert_git_clean`               | Asserts that a git repository is clean           |
| `assert_git_not_clean`           | Asserts that a git repository is not clean       |
| `assert_git_file_is_tracked`     | Checks if a file is tracked in git               |
| `assert_git_file_is_not_tracked` | Checks if a file is not tracked in git           |

### Data Provider

Run multiple test cases for a given function (aka "data provider").

Arguments:

1. `func_name`: The name of the function to be tested.
2. `args_per_row`: (Optional) The number of arguments in each row of the
   `TEST_CASES` array, defaults to `1`. Last argument is always the expected
   value.

Global Variables:

- `TEST_CASES`: An array containing test cases with their expected values.

**Examples:**

To run a function `add_numbers` with `TEST_CASES` containing three arguments per
row, you can call `dataprovider_run` like so:

```bash
# Function to test.
add_numbers() {
  echo "$(($1 + $2))"
}

@test "Test add_numbers" {
  # Numbers: first two are inputs, last is expected output.
  TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "add_numbers" 3
}
```

### Mocking

This Bats helper library provides command mocking functionality for BATS.

It allows to mock commands and check how they were called.

This is a very powerful feature that allows to test complex scenarios as unit
tests.

> [!NOTE]
> To run multiple mock assertions in a more convenient way, check out
> the [Step Runner](#step-runner) helper.

#### Setup functions

| Function               | Description                                | Arguments                        | Returns   |
|------------------------|--------------------------------------------|----------------------------------|-----------|
| `setup_mock`           | Setup mock support. Call from `setup()`    | None                             | None      |
| `mock_create`          | Creates a mock program that can be tracked | None                             | Mock path |
| `mock_command`         | Mock provided command                      | `command_name`                   | Mock path |
| `mock_set_output`      | Sets the output of the mock                | `mock`, `output`, `[call_index]` | None      |
| `mock_set_status`      | Sets the exit status of the mock           | `mock`, `status`, `[call_index]` | None      |
| `mock_set_side_effect` | Sets shell code to run when mock executes  | `mock`, `code`, `[call_index]`   | None      |

#### Assertion functions

| Function             | Description                                | Arguments                          | Returns          |
|----------------------|--------------------------------------------|------------------------------------|------------------|
| `mock_get_call_args` | Returns arguments the mock was called with | `mock`, `[call_index]`             | Arguments string |
| `mock_get_call_num`  | Returns number of times mock was called    | `mock`                             | Call count       |
| `mock_get_call_user` | Returns user the mock was called with      | `mock`, `[call_index]`             | User name        |
| `mock_get_call_env`  | Returns env variable value from mock call  | `mock`, `var_name`, `[call_index]` | Variable value   |

#### Example

```bash
setup() {
  setup_mock
}

# Example to test the notify.sh script that uses curl to send a notification to external system.
@test "Notify" {
  app_id="9876543210"

  # Mock curl command.
  mock_curl="$(mock_command "curl")"

  # Setup mock responses for curl call with specific arguments in notify.sh.
  mock_set_output "${mock_curl}" "12345678910-1234567890-${app_id}-12345" 1
  mock_set_output "${mock_curl}" "201" 2

  run ./notify.sh
  assert_success

  # Single line mock assertion example.
  assert_equal "-s -X GET https://api.example.com/v2/applications.json" "$(mock_get_call_args "${mock_curl}" 1)"
  # Multi-line mock assertion example.
  assert_equal '-X POST https://api.example.com/v2/applications/9876543210/deployments.json -d {
  "deployment": {
    "description": "example description",
  }
}' "$(mock_get_call_args "${mock_curl}" 2)"
}
```

### Step Runner

When working with mocks, you would have to setup a mock for each command call
with the expected argument numbers, return value, possible output and an index
of the call. Then, you would run the code to be tested and run assertions for
each of the
mocked commands. For large scripts maintaining both parts becomes a tedious
task.

The Step Runner allows to setup and process a sequence of string and mocked
command
assertions. It helps to make maintenance of complex tests easier.

Consider this example:

```bash
# Declare STEPS as a global variable, as `process_steps` needs to be called
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
  "@drush cache-rebuild # 0 # Cache rebuilt # touch /tmp/cache-cleared"

  # Mock command with wildcard (*) - accepts any arguments.
  "@git * # 0 # Git operation successful"

  # Mock command with escaped hash (\#) in URL - use \# for literal # in arguments.
  "@curl https://example.com/page\#anchor # 0 # Response body"

  # Assert that the output contains the substring "Hello world".
  "Hello world"

  # Assert that the output does NOT contain the substring "Goodbye world".
  # The leading "- " indicates negation.
  "- Goodbye world"
)

# Setup phase: creates mocks and returns references to them.
mocks="$(process_steps "setup")"

# Run the code under test.
run ./my-script.sh

# Assert phase: verifies mocks were called correctly and output assertions pass.
process_steps "assert" "$mocks"
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

##### Substring presence

`<substring>`

Assert that the output contains the given substring.

##### Substring absence

`- <substring>`

Assert that the output does not contain the specified substring.
Starts with `- ` (minus followed by a space).

### Helpers

| Function Name             | Description                                                                   |
|---------------------------|-------------------------------------------------------------------------------|
| `add_var_to_file`         | Adds a variable assignment to a file and creates a backup                     |
| `restore_file`            | Restores a file from its backup created by add_var_to_file                    |
| `read_env`                | Reads .env file and evaluates variable expressions in that context            |
| `format_error`            | Formats error messages with decorative borders and includes command output    |
| `flunk`                   | Causes a test to fail with an optional error message                          |
| `mktouch`                 | Creates a file and any necessary parent directories                           |
| `fixture_export_codebase` | Export codebase source code at the latest commit to the destination directory |
| `fixture_prepare_dir`     | Prepares a directory for fixture use by removing existing content             |
| `random_string`           | Generates a random alphanumeric string of specified length                    |
| `trim_file`               | Removes the last line from a file                                             |
| `tui_run`                 | Runs a TUI script with predefined answers, simulating user input              |

## Acknowledgments

The mocking functionality is based on
the [bats-mock](https://github.com/grayhemp/bats-mock) project.
A special thank you to the contributors for their original work.

## Maintenance

    npm install

    npm run lint

    npm run test

### Publishing

    npm version minor

    git push

    npm publish

---
_This repository was created using the [Scaffold](https://getscaffold.dev/)
project template_
