# Migration

Every name below still works and will keep working until `v2.1`. Each one prints a notice on file descriptor 3 when it is used, naming its replacement, so it shows up in the BATS output without being captured by `run` or by command substitution:

```text
Deprecated: 'assert_not_git_repo' will be removed in v2.1. Use 'assert_git_not_repo' instead.
```

Set `BATS_HELPERS_DEPRECATION_QUIET` to any non-empty value to silence those notices while you migrate:

```bash
export BATS_HELPERS_DEPRECATION_QUIET=1
```

A deprecated variable is used only when its replacement is unset or empty, so exporting the replacement as an empty string falls back to the old name rather than taking precedence. `BATS_HELPERS_ASSERT_DIR_EXCLUDE` is the exception: it holds an array, and a value test would read element 0 alone and fall back wrongly for an array such as `('' 'foo')`, so it falls back only when the replacement is *unset*. A declared empty array takes precedence over `ASSERT_DIR_EXCLUDE` rather than falling back to it.

## Functions

| Deprecated | Replacement | Notes |
| --- | --- | --- |
| `assert_contains` | `assert_string_contains` | Arguments swap: the old form took the needle first, the replacement takes the string first. |
| `assert_not_contains` | `assert_string_not_contains` | Arguments swap, as above. |
| `random_string` | `string_random` | |
| `assert_not_git_repo` | `assert_git_not_repo` | |
| `assert_git_file_is_tracked` | `assert_git_file_tracked` | |
| `assert_git_file_is_not_tracked` | `assert_git_file_not_tracked` | |
| `mktouch` | `file_mktouch` | |
| `trim_file` | `file_trim` | |
| `read_env` | `file_read_env` | |
| `add_var_to_file` | `file_add_var` | |
| `restore_file` | `file_restore` | |
| `run_steps` | `steps_run` | |
| `setup_mock` | `mock_setup` | |

Apart from the two `contains` renames, each replacement keeps the arguments, the standard output and the return semantics, so a call is updated by swapping the name alone. `assert_contains` and `assert_not_contains` take the needle first, while their replacements take the haystack first, so those two swap their arguments as well:

```bash
assert_contains "needle" "some needle in a haystack"

assert_string_contains "some needle in a haystack" "needle"
```

## Variables

| Deprecated | Replacement | Notes |
| --- | --- | --- |
| `BATS_MOCK_TMPDIR` | `BATS_HELPERS_MOCK_TMPDIR` | |
| `_USER` | `BATS_HELPERS_MOCK_USER` | |
| `ASSERT_DIR_EXCLUDE` | `BATS_HELPERS_ASSERT_DIR_EXCLUDE` | An array. Set-but-empty counts as set, so an empty replacement does not fall back. |
| `RUN_STEPS_DEBUG` | `BATS_HELPERS_STEPS_DEBUG` | |
| `BATS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` | |
| `BATS_HELPERS_BACKUP_DIR` | `BATS_HELPERS_FILE_BACKUP_DIR` | Renamed so the name carries its owning module, as every other variable does. |

`mock_setup` exports `BATS_HELPERS_MOCK_TMPDIR` rather than `BATS_MOCK_TMPDIR`. The old name is still read as an input, but it is no longer written, so a test that reads the mock directory back after `mock_setup` has to read the new name. `_mock_resolve_tmp` also names the new variable when it cannot resolve a directory, so a test asserting on `Set BATS_MOCK_TMPDIR to a writable directory` has to be updated.

## Arguments and values

| Deprecated | Replacement | Notes |
| --- | --- | --- |
| `assert_failure --status <n>` | `assert_failure_status <n>` | Behaviour is unchanged. `--status 0` was already an error; use `assert_success`. |
| `assert_files_equal <a> <b> 1` | `assert_files_equal_ignore_spaces <a> <b>` | Only the `1` form is deprecated. `assert_files_equal <a> <b>` and `assert_files_equal <a> <b> 0` stay as they are. |
| `assert_files_not_equal <a> <b> 1` | `assert_files_not_equal_ignore_spaces <a> <b>` | As above. |
| `nothing` as a TUI answer | an empty string | `declare -a answers=("nothing")` becomes `declare -a answers=("")`. |

An empty string is what sends a blank line now, and `nothing` still sends one while printing a notice. Once that special case is removed, `nothing` will reach the script as the seven characters it spells, so a script that legitimately expects that answer becomes testable:

```bash
tui_run "My site" "nothing" "yes"

tui_run "My site" "" "yes"
```

## Behaviour changes

These are not renames: the name is unchanged and no notice is printed, so review call sites when upgrading.

| Surface | Before | Now |
| --- | --- | --- |
| `assert_dir_contains_string`, `assert_dir_not_contains_string` | Case-sensitive; the string was read as a `grep` basic regular expression; the matched file list was printed to STDOUT | Case-insensitive and literal, with `_case` twins; a regular expression search is `assert_dir_matches` and friends, reading extended regular expressions; matched files are reported inside the failure report only |
