# Deprecations

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

The variables follow the same pattern. The old name is read only when the new one is unset or empty, so setting both to real values leaves the new one in charge. `BATS_HELPERS_ASSERT_DIR_EXCLUDE` is the exception: it holds an array, and a value test would read element 0 alone and fall back wrongly for an array such as `('' 'foo')`, so it falls back only when the replacement is *unset*. A declared empty array takes precedence over `ASSERT_DIR_EXCLUDE` rather than falling back to it.

| Deprecated                             | Use instead                                    |
|----------------------------------------|------------------------------------------------|
| `RUN_STEPS_DEBUG`                      | `BATS_HELPERS_STEPS_DEBUG`                     |
| `ASSERT_DIR_EXCLUDE`                   | `BATS_HELPERS_ASSERT_DIR_EXCLUDE`              |
| `BATS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` |
| `BATS_MOCK_TMPDIR`                     | `BATS_HELPERS_MOCK_TMPDIR`                     |
| `_USER`                                | `BATS_HELPERS_MOCK_USER`                       |
| `BATS_HELPERS_BACKUP_DIR`              | `BATS_HELPERS_FILE_BACKUP_DIR`                 |

`mock_setup` now exports `BATS_HELPERS_MOCK_TMPDIR` rather than `BATS_MOCK_TMPDIR`. The old name is still read as an input, but it is no longer written, so a test that reads the mock directory back after `mock_setup` has to read the new name. `_mock_resolve_tmp` also names the new variable when it cannot resolve a directory, so a test asserting on `Set BATS_MOCK_TMPDIR to a writable directory` has to be updated.

Every helper in a module shares one prefix - `steps_*`, `mock_*`, `file_*`, `string_*` - matching how bats-core namespaces `bats_*` and bats-support namespaces `batslib_*`. Apart from the two below, each replacement keeps the arguments, the standard output and the return semantics, so a call is updated by swapping the name alone.

`assert_contains` and `assert_not_contains` take the needle first, while their replacements take the haystack first, so a call has to swap its arguments as well as change its name:

```bash
assert_contains "needle" "some needle in a haystack"

assert_string_contains "some needle in a haystack" "needle"
```

The `nothing` answer to `tui_run` is deprecated in the same way. An empty string is what sends a blank line now, and `nothing` still sends one while printing a notice, so the literal string becomes answerable once it is removed:

```bash
tui_run "My site" "nothing" "yes"

tui_run "My site" "" "yes"
```

The notice is written to file descriptor 3, so it shows up in the BATS output without being captured by `run` or by command substitution:

```text
Deprecated: 'assert_not_git_repo' will be removed in the next version. Use 'assert_git_not_repo' instead.
```

Set `BATS_HELPERS_DEPRECATION_QUIET` to any non-empty value to silence every notice:

```bash
export BATS_HELPERS_DEPRECATION_QUIET=1
```

See [`MIGRATION.md`](../MIGRATION.md) for every deprecated function, variable and argument, together with its replacement, in one place.
