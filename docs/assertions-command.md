# Command assertions

Assertions for a command run with `run` - its output, its exit status and its standard error.

Source: [`src/assert.command.bash`](../src/assert.command.bash)

## Output

Use these after running a command with `run`.

| Function Name                       | Description                                          |
|-------------------------------------|------------------------------------------------------|
| `assert_success`                    | Asserts that a command succeeds                      |
| `assert_failure`                    | Asserts that a command fails                         |
| `assert_output`                     | Asserts that a command outputs an exact string       |
| `assert_output_contains`            | Asserts that output contains a substring             |
| `assert_output_not_contains`        | Asserts that output does not contain a substring     |
| `assert_output_matches`             | Asserts that output matches a regular expression     |
| `assert_output_not_matches`         | Asserts that output does not match a regular expression |
| `assert_output_matches_format`      | Asserts that output matches a format string          |
| `assert_output_not_matches_format`  | Asserts that output does not match a format string   |

The six `contains`, `matches` and `matches_format` assertions each have a `_case` twin that matches case-sensitively - `assert_output_contains_case`, `assert_output_not_matches_format_case` and so on. See [Match modes](match-modes.md).

## Exit statuses

| Function Name                     | Description                                             |
|-----------------------------------|---------------------------------------------------------|
| `assert_status`                   | Asserts that a command exits with an exact status       |
| `assert_failure_status`           | Asserts that a command fails with an exact status       |
| `assert_status_general_error`     | Asserts that a command exits with status `1`            |
| `assert_status_command_not_found` | Asserts that a command exits with status `127`          |

`assert_success` and `assert_failure` divide the world into zero and non-zero, which is not enough for a tool that separates a usage error from a runtime failure by exiting `2` rather than `1`. Assert the status itself:

```bash
run ./script.sh --nonsense

assert_status 2
```

`assert_failure_status` covers both the failure and the status it failed with in one call:

```bash
run ./script.sh --nonsense

assert_failure_status 2
assert_failure_status 2 "Usage: script.sh [--verbose] <path>"
```

### Statuses that mean more than a failure

Two statuses mean something other than the code under test deciding to fail, and both satisfy a bare `assert_failure` exactly as well as the intended error path does. Every report that prints a status names them:

```text
-- Command exited with an unexpected status --
expected : 2
actual   : 127 (command not found)
--
```

```text
-- Command failed --
status : 137 (killed by SIGKILL)
--
```

A status of `127` is what a shell returns for a command it could not find, so a test that passes because the binary under test is missing is caught rather than counted. A status above `128` is how a shell reports a process a signal killed, and the signal is named from the running platform's own table. A program is free to exit with such a status of its own accord, so the name says which signal the number stands for, not that a signal was necessarily involved.

Where a missing command *is* the expected outcome, assert it as such:

```bash
# 'run -127' stops bats warning about the status it would otherwise read as a
# mistake in the test.
run -127 ./wrapper.sh

assert_status_command_not_found
```

## Standard error

| Function Name                       | Description                                                 |
|-------------------------------------|-------------------------------------------------------------|
| `assert_stderr`                     | Asserts that a command writes an exact string to STDERR     |
| `assert_stderr_contains`            | Asserts that STDERR contains a substring                    |
| `assert_stderr_not_contains`        | Asserts that STDERR does not contain a substring            |
| `assert_stderr_matches`             | Asserts that STDERR matches a regular expression            |
| `assert_stderr_not_matches`         | Asserts that STDERR does not match a regular expression     |
| `assert_stderr_matches_format`      | Asserts that STDERR matches a format string                 |
| `assert_stderr_not_matches_format`  | Asserts that STDERR does not match a format string          |
| `assert_stderr_empty`               | Asserts that a command wrote nothing to STDERR              |
| `assert_stderr_captured`            | Asserts that STDERR was captured separately from the output |

The six `contains`, `matches` and `matches_format` assertions each have a `_case` twin that matches case-sensitively. See [Match modes](match-modes.md).

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

A captured STDERR that is not empty becomes a row of the reports the exit status assertions raise, so a command that failed shows why rather than only that it did:

```text
-- Command failed --
status : 3
output : Reading /etc/app/config.yml
stderr : Error: config file not found
--
```

A capture lives only until the next `run`: a plain one clears `$stderr`, so the assertions always read the most recent `run --separate-stderr`. Pass the option to the `run` whose STDERR is being asserted on, and assert directly after it.
