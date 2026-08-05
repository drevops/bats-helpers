# File utilities

Utilities for creating, trimming, backing up and restoring the files a test works with.

Source: [`src/file.bash`](../src/file.bash)

| Function Name      | Description                                                                |
|--------------------|----------------------------------------------------------------------------|
| `file_mktouch`     | Creates a file and any missing parent directories                          |
| `file_trim`        | Removes the last line of a file in place                                   |
| `file_read_env`    | Evaluates an expression with the variables from the `./.env` file in scope |
| `file_backup_path` | Resolves the backup location of a file                                     |
| `file_add_var`     | Appends a variable assignment to a file, backing the file up first         |
| `file_restore`     | Restores a file from the backup taken by `file_add_var`                    |

| Variable                       | Read by                                            | Description                                                        |
|--------------------------------|----------------------------------------------------|--------------------------------------------------------------------|
| `BATS_HELPERS_FILE_BACKUP_DIR` | `file_add_var`, `file_restore`, `file_backup_path` | Backup root. Defaults to `${BATS_TEST_TMPDIR}/bats-helpers-backup` |

## File backups

`file_add_var` backs a file up before modifying it and `file_restore` puts that backup back. Backups are written below `${BATS_TEST_TMPDIR}/bats-helpers-backup`, mirroring the source path, so BATS removes them together with the rest of the test sandbox and concurrent runs cannot overwrite each other's backups.

Set `BATS_HELPERS_FILE_BACKUP_DIR` to store them elsewhere. Only the default location carries the guarantees above - a directory outside `${BATS_TEST_TMPDIR}` is not removed by BATS and is shared with concurrent runs:

```bash
export BATS_HELPERS_FILE_BACKUP_DIR="${BATS_TEST_TMPDIR}/backups"
```

Use `file_backup_path` to resolve where a given file's backup is stored:

```bash
assert_file_exists "$(file_backup_path "${BATS_TEST_TMPDIR}/.env")"
```
