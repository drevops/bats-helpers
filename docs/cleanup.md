# Cleanup

Cleanup that belongs to one test can be registered next to the code that created the thing it removes, instead of being written into a shared `teardown` or repeated on every early-exit path:

```bash
@test "Build writes an artifact" {
  build_dir="${BATS_TEST_TMPDIR}/build"
  mkdir -p "${build_dir}"
  cleanup_register rm -rf "${build_dir}"

  run ./build.sh "${build_dir}"
  assert_success
  assert_file_exists "${build_dir}/artifact.tar"
}
```

Source: [`src/cleanup.bash`](../src/cleanup.bash)

| Function                | Description                                                           | Arguments              | Returns       |
|-------------------------|-----------------------------------------------------------------------|------------------------|---------------|
| `cleanup_register`      | Registers a command to run once the current test has finished         | `command`, `[args...]` | None          |
| `cleanup_run`           | Runs the registered commands in reverse order. Call from `teardown()` | None                   | None          |
| `cleanup_registry_path` | Resolves the file the registry is stored in                           | None                   | Registry path |

| Variable                   | Description                                                               |
|----------------------------|---------------------------------------------------------------------------|
| `BATS_HELPERS_CLEANUP_DIR` | Directory holding the cleanup registry. Defaults to `${BATS_TEST_TMPDIR}` |

## Composing with your teardown

`teardown` belongs to your test file, so the library does not define it. Call `cleanup_run` from your own `teardown`, the way `mock_setup` is called from `setup`:

```bash
setup() {
  mock_setup
}

teardown() {
  cleanup_run
}
```

Without that call nothing is ever run, so wire it up once per test file - or once in the helper every test file loads.

## Order and statuses

Registrations run in reverse order, so a resource created inside another one is removed while the outer one still exists:

```bash
cleanup_register rm -rf "${repo_dir}"
cleanup_register git -C "${repo_dir}" worktree remove "${worktree_dir}"
```

BATS runs `teardown` after a test whether it passed or failed, so the registered commands run either way. From there:

- A cleanup that succeeds leaves the test's own result alone. A test that failed still reports its own failure, not the cleanup.
- A cleanup that fails fails an otherwise-passing test, and reports the command and its exit status. A cleanup that silently fails is how leaked state accumulates.
- A cleanup that fails does not stop the ones registered before it, and does not mask a failure that preceded it.

## Registering a command

Arguments are quoted when they are registered, so reassigning a variable afterwards cannot redirect the command:

```bash
dir="${BATS_TEST_TMPDIR}/first"
cleanup_register rm -rf "${dir}"

# The registered command still removes "first".
dir="${BATS_TEST_TMPDIR}/second"
```

Anything that needs a pipeline, a redirection or several statements is registered as a function:

```bash
archive_logs() {
  tar -czf "${1}.tar.gz" "${1}"
}

cleanup_register archive_logs "${log_dir}"
```

## Cleanup sandbox

The registry is the file `${BATS_TEST_TMPDIR}/bats-helpers-cleanup`, so BATS removes it together with the rest of the test sandbox and concurrent runs cannot overwrite each other's registrations. Keeping it on disk rather than in a variable also means a registration made inside a subshell - under `run`, a command substitution or a pipeline - still reaches `cleanup_run`.

Set `BATS_HELPERS_CLEANUP_DIR` to store the registry elsewhere. Only the default location carries the guarantees above - a directory outside `${BATS_TEST_TMPDIR}` is not removed by BATS and is shared with concurrent runs:

```bash
export BATS_HELPERS_CLEANUP_DIR="${BATS_TEST_TMPDIR}/cleanup"
```

Use `cleanup_registry_path` to resolve where the registry is stored:

```bash
assert_file_not_exists "$(cleanup_registry_path)"
```

`cleanup_run` drains the registry before running anything, so calling it a second time - from the test body and again from `teardown`, say - runs nothing.
