# Step runner

Mocking by hand means setting up a mock for each command call with its expected arguments, return value, possible output and call index, then running the code under test and asserting against each mock in turn. For a large script, keeping those two halves in step becomes a tedious task.

The step runner sets up and processes a sequence of string and mocked command assertions, so both halves are declared once in one array.

Source: [`src/steps.bash`](../src/steps.bash)

| Function    | Description                                          | Arguments            | Returns    |
|-------------|------------------------------------------------------|----------------------|------------|
| `steps_run` | Runs the `setup` or the `assert` phase of the `STEPS` array | `phase`, `[mocks]` | Mock references |

| Variable                   | Description                                                                  |
|----------------------------|------------------------------------------------------------------------------|
| `STEPS`                    | Array of steps to process. Declared with `declare -a` above the call         |
| `BATS_HELPERS_STEPS_DEBUG` | Set to `1` to print every parsing and matching decision to file descriptor 3 |

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

## Step types

A step can be one of the following types:

- [Command](#command) - mock a command
- [Substring presence](#substring-presence) - assert output contains string
- [Substring absence](#substring-absence) - assert output does NOT contain string
- [Expected call](#expected-call) - assert the ordered sequence of mocked calls

### Command

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
  - Can be omitted and the output given in its place, unless that output is all digits, which parses as a status
- `<mock_output>` - output to return (optional)
- `<mock_side_effect>` - Bash code executed when mock is called (optional):
  - Useful for creating files/directories, setting env vars, logging, simulating complex behaviors
  - Executed in the context of the mock, not the test
  - Runs after output is generated but before exit status is returned
  - Chain multiple commands with `;` or `&&`
  - Use `${BATS_TEST_TMPDIR}` for temporary files
  - Each invocation of the same command can have different side effects

A step may contain at most three `#` characters and no consecutive `##`. Escape a literal `#` in the arguments as `\#`.

### Substring presence

`<substring>`

Assert that the output contains the given substring.

### Substring absence

`- <substring>`

Assert that the output does not contain the specified substring. Starts with `- ` (minus followed by a space).

### Expected call

`= <call>`

Add a call to the expected sequence. Starts with `= ` (equals followed by a space), and the call is written in the serialisation the [call log](mocking.md#call-log) documents. All such steps together are the complete ordered sequence of mocked calls, asserted once during the assert phase.

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

## Debugging

Set `BATS_HELPERS_STEPS_DEBUG` to `1` to print the parsing and matching decisions of every step to file descriptor 3:

```bash
export BATS_HELPERS_STEPS_DEBUG=1
```
