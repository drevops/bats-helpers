# Retry

Anything asynchronous - a background process writing a file, a service coming up, a lock being released - is waited for by re-running the check rather than by sleeping for a fixed time:

```bash
@test "Server comes up" {
  ./start-server.sh &

  retry_run 20 0.25 curl -sf "http://localhost:8080/health"
}
```

Source: [`src/retry.bash`](../src/retry.bash)

| Function    | Description                                                    | Arguments                                   | Returns |
|-------------|----------------------------------------------------------------|---------------------------------------------|---------|
| `retry_run` | Runs a command until it succeeds or until a bound is reached   | `attempts`, `delay`, `command`, `[args...]` | None    |

| Variable                      | Description                                                                             |
|-------------------------------|-----------------------------------------------------------------------------------------|
| `BATS_HELPERS_RETRY_TIMEOUT`  | Overall deadline in whole seconds, on top of the attempt count. Unset means no deadline  |
| `BATS_HELPERS_RETRY_ATTEMPTS` | Set by `retry_run` to the attempts made, which on success is the attempt that succeeded  |
| `BATS_HELPERS_RETRY_OUTPUT`   | Set by `retry_run` to the STDOUT and STDERR of the last attempt                          |
| `BATS_HELPERS_RETRY_ELAPSED`  | Set by `retry_run` to the whole seconds the retry spent                                  |

The first attempt runs immediately and the last one is not followed by a wait, so a condition that is already true costs no delay at all and an exhausted retry does not end on a delay that changes nothing. A delay may carry a fractional part.

Any command is retryable, including the library's own assertions, so nothing has to be reimplemented to be waited for:

```bash
retry_run 10 0.5 assert_file_exists "${build_dir}/artifact.tar"
retry_run 10 0.5 assert_file_contains "${log}" "Ready"
```

Anything that needs a pipeline, a redirection or several statements is retried as a function, the same way it is registered for cleanup:

```bash
queue_is_drained() {
  [ "$(wc -l <"${queue}")" -eq 0 ]
}

retry_run 30 1 queue_is_drained
```

## Deadline

`BATS_HELPERS_RETRY_TIMEOUT` bounds the whole retry in seconds, independently of the attempt count, so a generous attempt count can be capped by the time the suite can afford to spend:

```bash
export BATS_HELPERS_RETRY_TIMEOUT=10

retry_run 200 0.05 assert_file_exists "${socket}"
```

Whichever bound is reached first ends the retry. The deadline is checked after each failed attempt: once it has passed, the helper stops rather than waiting again. It never interrupts an attempt that is already running, so a slow command can overshoot it.

The deadline is in whole seconds, because `SECONDS` is the only clock available across the Bash versions the library supports.

## Reporting

An immediate success is silent. A success that took more than one attempt writes a notice to file descriptor 3, so a test that has quietly degraded to a fourth attempt does not read like a healthy one:

```text
Retried: 'curl' succeeded on attempt 4 of 20 after 1 seconds.
```

Three variables describe the run that just finished:

| Variable                      | Description                                                          |
|-------------------------------|----------------------------------------------------------------------|
| `BATS_HELPERS_RETRY_ATTEMPTS` | Attempts made, which on success is the attempt that succeeded        |
| `BATS_HELPERS_RETRY_OUTPUT`   | STDOUT and STDERR of the last attempt                                |
| `BATS_HELPERS_RETRY_ELAPSED`  | Whole seconds spent                                                  |

```bash
retry_run 10 0.5 curl -sf "http://localhost:8080/health"

assert_string_contains "${BATS_HELPERS_RETRY_OUTPUT}" "\"status\":\"ok\""
```

When every bound is exhausted the failure names the elapsed time, the attempt count and the last observed state, so the run does not have to be reproduced by hand to find out what it was doing:

```text
Command 'curl' did not succeed within 5 attempt(s).
attempts: 5
elapsed: 4 second(s)
last status: 7
last output: 'curl: (7) Failed to connect to localhost port 8080'
```

## What an attempt sees

Each attempt runs in a subshell with its output captured, the way `run` does. Two consequences follow from that, and both match `run`:

- `set -e` does not apply inside an attempt, so only the final exit status decides whether the attempt succeeded.
- A variable an attempt sets does not reach the test. An attempt that has to publish a value writes a file.

A command that does not resolve is rejected before the first attempt rather than retried, so a typo is reported immediately instead of after the whole delay budget has been spent. A command that is expected to appear later is probed for by a function:

```bash
binary_is_installed() {
  command -v "${1}" >/dev/null 2>&1
}

retry_run 10 1 binary_is_installed "mytool"
```
