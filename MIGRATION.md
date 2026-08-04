# Migration

Every name below still works and will keep working until `v2`. Each one prints a notice on file descriptor 3 when it is used, naming its replacement. Set `BATS_HELPERS_DEPRECATION_QUIET` to any non-empty value to silence those notices while you migrate.

A deprecated variable is read only when its replacement is unset or empty, so exporting the replacement as an empty string falls back to the old name rather than taking precedence.

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

## Variables

| Deprecated | Replacement | Notes |
| --- | --- | --- |
| `BATS_MOCK_TMPDIR` | `BATS_HELPERS_MOCK_TMPDIR` | |
| `_USER` | `BATS_HELPERS_MOCK_USER` | |
| `ASSERT_DIR_EXCLUDE` | `BATS_HELPERS_ASSERT_DIR_EXCLUDE` | An array. Set-but-empty counts as set, so an empty replacement does not fall back. |
| `RUN_STEPS_DEBUG` | `BATS_HELPERS_STEPS_DEBUG` | |
| `BATS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` | |
| `BATS_HELPERS_BACKUP_DIR` | `BATS_HELPERS_FILE_BACKUP_DIR` | Renamed so the name carries its owning module, as every other variable does. |

## Arguments and values

| Deprecated | Replacement | Notes |
| --- | --- | --- |
| `assert_failure --status <n>` | `assert_failure_status <n>` | Behaviour is unchanged. `--status 0` was already an error; use `assert_success`. |
| `assert_files_equal <a> <b> 1` | `assert_files_equal_ignore_spaces <a> <b>` | Only the `1` form is deprecated. `assert_files_equal <a> <b>` and `assert_files_equal <a> <b> 0` stay as they are. |
| `assert_files_not_equal <a> <b> 1` | `assert_files_not_equal_ignore_spaces <a> <b>` | As above. |
| `nothing` as a TUI answer | an empty string | `declare -a answers=("nothing")` becomes `declare -a answers=("")`. |
