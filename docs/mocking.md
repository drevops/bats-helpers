# Mocking

This Bats helper library provides command mocking functionality for BATS.

It allows to mock commands and check how they were called.

This is a very powerful feature that allows to test complex scenarios as unit tests.

Source: [`src/mock.bash`](../src/mock.bash)

> [!NOTE]
> To run multiple mock assertions in a more convenient way, check out the [Step runner](steps.md) helper.

## Setup functions

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

## Assertion functions

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

## Mock directory

`mock_setup` writes the mocks to `${BATS_TEST_TMPDIR}/bats-helpers-mock` and puts that directory first on `PATH`, so BATS removes the mocks together with the rest of the test sandbox and concurrent runs cannot delete each other's mocks.

Set `BATS_HELPERS_MOCK_TMPDIR` to store them elsewhere; the mocks are written to a `bats-helpers-mock` directory below it. The guarantees above come from staying within the test sandbox - a directory outside `${BATS_TEST_TMPDIR}` is not removed by BATS and is shared with concurrent runs:

```bash
export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/mocks"
```

`mock_setup` also exports `BATS_HELPERS_MOCK_TMPDIR` with the resolved path, so a test can read back where the mocks ended up.

`mock_get_call_user` reports the user each call was made as. It defaults to `id -un`; set `BATS_HELPERS_MOCK_USER` to report a different one:

```bash
export BATS_HELPERS_MOCK_USER="deploy"
```

## Call log

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

## Argument specifications

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

A response is written literally, whichever form sets it, so a value such as `-n`, or one holding a backslash, reaches the caller unchanged.

The first argument of `mock_spec_arg` after the specification is the position: a one-based argument index, or `*` for "some argument". The second is the matcher:

| Matcher       | Accepts when the argument                     |
|---------------|-----------------------------------------------|
| `equals`      | is exactly the value                          |
| `starts_with` | starts with the value                         |
| `ends_with`   | ends with the value                           |
| `contains`    | holds the value anywhere                      |
| `matches`     | matches the value as an extended regexp       |
| `present`     | exists, whatever its value. Takes no value    |

Every matcher takes a `not_` prefix. At a numeric position it negates that one argument; at `*` it requires that *no* argument matches, which is the negation of "some argument matches". `starts_with`, `ends_with`, `contains` and `matches` ignore case, and each takes a `_case` suffix to match case-sensitively, exactly as the [assertions](match-modes.md) do; `equals` compares exactly, as `assert_equal` does, and `present` reads no needle, so neither takes the suffix:

```bash
# Argument 2 is not a tag.
mock_spec_arg "${spec}" 2 not_matches '^v[0-9]+$'

# No argument is '--force'.
mock_spec_arg "${spec}" '*' not_equals "--force"

# Argument 1 holds 'Accept' with exactly this case.
mock_spec_arg "${spec}" 1 contains_case "Accept"
```

`mock_spec_count` pins how many arguments the call carries:

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

## Strictness

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

With no arguments it verifies every mock of the test; with arguments it verifies only the mocks named. The [step runner](steps.md) calls it for its own mocks at the end of the assert phase.

## Sandbox mode

Mocks are prepended to `PATH`, so a command the test forgot to mock resolves to the real one on the machine. A test that misses a network call, a package manager or a destructive command runs it for real, slowly and non-hermetically. Sandbox mode replaces `PATH` with the mock directory and a directory of the commands the test allowed, so a command that is neither mocked nor allowed does not run:

```bash
setup() {
  mock_setup
  mock_sandbox_enable
}

@test "Deploy" {
  mock_command "curl" >/dev/null

  run ./deploy.sh

  # 'curl' is answered by its mock. An unmocked 'aws' fails the call with
  # "Command 'aws' is not mocked and the mock sandbox is enabled" instead of
  # reaching the real one.
}
```

| Function                          | Description                                                     | Arguments        | Returns |
|-----------------------------------|-----------------------------------------------------------------|------------------|---------|
| `mock_sandbox_enable`             | Enables the mode. Arguments seed the allow-list                 | `[command...]`   | None    |
| `mock_sandbox_allow`              | Allows commands to run for real                                 | `command...`     | None    |
| `mock_sandbox_disable`            | Restores the `PATH` saved when the mode was enabled             | None             | None    |
| `mock_sandbox_enabled`            | Reports whether the mode is enabled                             | None             | `0` when enabled |
| `mock_sandbox_report`             | Prints the denied and the escaped commands                      | `[kind]`         | Report  |
| `mock_path_check`                 | Warns when `PATH` changed after `mock_setup`                    | None             | None    |

The mode is off until `mock_sandbox_enable` is called, so a suite that does not call it is unaffected. Calling it from `setup` turns it on for a whole file, and `mock_sandbox_disable` reopens the real `PATH` mid-test. BATS runs each test in its own process, so nothing has to be restored at the end of one.

> [!WARNING]
> This is not a security boundary. An absolute path reaches the real command whatever `PATH` holds, so `/usr/bin/curl` and `./script.sh` still run. The mode catches the command a test forgot to mock, not a command determined to run.

### Allowing a command to run for real

Some commands have to run: a `date` the test cannot predict, a `tar` that has to produce a real archive. `mock_sandbox_allow` puts them back within reach, and every call reaching one is recorded so that it stays visible:

```bash
mock_sandbox_enable "date" "tar"

# The same, after the fact.
mock_sandbox_allow "git"
```

An allowed command has to have a file on `PATH` when it is allowed, so a typo is reported at that line rather than as a puzzling failure later. A shell builtin never needs allowing: the shell answers it without a `PATH` lookup, so the mode never denies it.

The commands the library and the BATS harness run stay available, because the assertions, the file helpers, the generated mocks and `run` itself are built out of them: `bash`, `cat`, `chmod`, `cp`, `diff`, `dirname`, `find`, `grep`, `head`, `id`, `ln`, `ls`, `mkdir`, `mktemp`, `rm`, `sed`, `stat`, `touch` and `wc`. Mocking one of them shadows the sandbox entry, since the mock directory still comes first on `PATH`. `git` and `tar` are deliberately not in that set, so [git assertions](assertions-git.md) and `fixture_export_codebase` need them allowed to run inside the mode.

A [forwarding mock](#argument-specifications) reaches the real command the same way, so `mock_set_forward` inside the sandbox needs its command allowed as well.

### What escaped

`mock_sandbox_report` names every command that left the mock boundary, each one once, in the order they were first seen:

```text
Command 'aws' is not mocked and the mock sandbox denied it
Command 'date' ran for real, allowed by the mock sandbox
```

Pass `denied` or `allowed` to print one kind alone. `mock_verify` reads both: a denied command fails the verification, because it is a hole in the test, while an allowed one is printed to file descriptor 3, because it ran as the test asked and only has to stay visible.

```bash
teardown() {
  mock_verify
}
```

Without that call a script that swallows the failed command's exit status leaves the test passing, so wire `mock_verify` up whenever the mode is on.

The message reaches a Bash script under test, not only the test shell, because the mode installs an exported `command_not_found_handle`. A lookup that never consults it - `exec`, a compiled program starting a child, or a shell that does not implement the hook - fails with a plain `command not found` and exit status `127`, and leaves no entry in the report.

### When PATH is rewritten

Code under test that rewrites `PATH` disables the mocking silently, and the test then passes while exercising the real system - the same failure the sandbox exists to prevent, arriving through a different door. `mock_setup` records the `PATH` it produced and `mock_verify` compares it, so the rewrite is reported rather than left to be guessed at:

```text
Warning: 'PATH' changed after 'mock_setup' and no longer holds the mock directory '/.../bats-helpers-mock'. Mocked commands are not found and the real commands run instead.
```

A change that leaves the mock directory in place is reported too, in its own words, since the mocks still answer but everything else may resolve differently. Both go to file descriptor 3, alongside the deprecation notices, and neither fails the test on its own. `mock_path_check` performs the same check on demand.

## Example

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
