# Environment variables

Every variable the library defines, in one place. Each is also covered by the page of the feature that uses it. Variables that belong to bats-core - `BATS_TEST_TMPDIR`, `BATS_TMPDIR`, `BATS_TEST_DIRNAME`, `BATS_VERBOSE_RUN` - are read but not owned here, and are documented by [bats-core](https://bats-core.readthedocs.io/). `NO_COLOR` is read the same way: any non-empty value suppresses the colour of a diff in a failure report, following [the convention](https://no-color.org/).

`STEPS`, `TEST_CASES` and `SCRIPT_FILE` are the test data a consumer declares right above the call that reads it, so they stay short and unprefixed. Every other variable the library defines carries the `BATS_HELPERS_` prefix. The prefix covers what the library provides, not what it consumes, which is why the variables named above stay as they are.

| Variable                                       | Read by                                                       | Description                                                                                 |
|------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `STEPS`                                        | `steps_run`                                                   | Array of steps to process                                                                   |
| `TEST_CASES`                                   | `dataprovider_run`                                            | Array of test cases, each row ending with its expected value                                |
| `SCRIPT_FILE`                                  | `tui_run`                                                     | Path to the script to run, relative to the current directory                                |
| `BATS_HELPERS_TUI_TIMEOUT`                     | `tui_run`                                                     | Whole seconds the script is given to finish. Defaults to `60`                               |
| `BATS_HELPERS_TUI_ANSWERS`                     | `tui_assert_prompts`, `tui_assert_prompts_case`               | Set by `tui_run` to the number of answers submitted                                         |
| `BATS_HELPERS_STEPS_DEBUG`                     | `steps_run`                                                   | Set to `1` to print every parsing and matching decision to file descriptor 3                |
| `BATS_HELPERS_ASSERT_DIR_EXCLUDE`              | `assert_dir_contains_string`, `assert_dir_matches` and their variants | Array of directory names to exclude from the search, on top of the always-excluded four     |
| `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` | `fixture_export_codebase`                                     | Set to `1` to enable the export; anything else makes the function a no-op                   |
| `BATS_HELPERS_FILE_BACKUP_DIR`                 | `file_add_var`, `file_restore`, `file_backup_path`            | Backup root. Defaults to `${BATS_TEST_TMPDIR}/bats-helpers-backup`                          |
| `BATS_HELPERS_CLEANUP_DIR`                     | `cleanup_register`, `cleanup_run`, `cleanup_registry_path`    | Directory holding the cleanup registry. Defaults to `${BATS_TEST_TMPDIR}`                   |
| `BATS_HELPERS_RETRY_TIMEOUT`                   | `retry_run`                                                   | Overall deadline in whole seconds, on top of the attempt count. Unset means no deadline     |
| `BATS_HELPERS_RETRY_ATTEMPTS`                  | `retry_run`                                                   | Set by `retry_run` to the attempts made, which on success is the attempt that succeeded     |
| `BATS_HELPERS_RETRY_OUTPUT`                    | `retry_run`                                                   | Set by `retry_run` to the STDOUT and STDERR of the last attempt                             |
| `BATS_HELPERS_RETRY_ELAPSED`                   | `retry_run`                                                   | Set by `retry_run` to the whole seconds the retry spent                                     |
| `BATS_HELPERS_MOCK_TMPDIR`                     | `mock_setup`, `mock_create`                                   | Directory the mocks are written below. Defaults to `${BATS_TEST_TMPDIR}`, and `mock_setup` exports the resolved path |
| `BATS_HELPERS_MOCK_USER`                       | `mock_get_call_user`                                          | User a mock call is reported as. Defaults to `id -un`                                       |
| `BATS_HELPERS_MOCK_STRICT`                     | `mock_create`                                                 | Set to `0` to answer the calls a mock's expectations do not cover. Defaults to `1`, and is read when the mock is created |
| `BATS_HELPERS_MOCK_SANDBOX_REPORT`             | `_mock_sandbox_deny`                                          | Path to the sandbox report. Exported by `mock_sandbox_enable` so that a denial recorded in a child process reaches it |
| `BATS_HELPERS_REPORT_COLOR`                    | `format_error`                                                | `0` to never colour a diff, `1` to colour it whenever `diff` supports the flag. Unset or empty defers to `NO_COLOR` |
| `BATS_HELPERS_DEPRECATION_QUIET`               | every module                                                  | Set to any non-empty value to silence every deprecation notice                              |
