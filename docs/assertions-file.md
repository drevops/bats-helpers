# File assertions

Assertions for files, directories and symbolic links.

Source: [`src/assert.file.bash`](../src/assert.file.bash)

## Files

| Function Name                    | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `assert_file_exists`             | Asserts that a file exists                             |
| `assert_file_not_exists`         | Asserts that a file does not exist                     |
| `assert_file_contains`           | Asserts that a file contains a string                  |
| `assert_file_not_contains`       | Asserts that a file does not contain a string          |
| `assert_file_matches`            | Asserts that a file matches a regular expression       |
| `assert_file_not_matches`        | Asserts that a file does not match a regular expression |
| `assert_file_matches_format`     | Asserts that a file matches a format string            |
| `assert_file_not_matches_format` | Asserts that a file does not match a format string     |
| `assert_files_equal`             | Asserts that two files are equal                       |
| `assert_files_equal_ignore_spaces` | Asserts that two files are equal, ignoring blank lines and whitespace changes |
| `assert_files_not_equal`         | Asserts that two files are not equal                   |
| `assert_files_not_equal_ignore_spaces` | Asserts that two files are not equal, ignoring blank lines and whitespace changes |
| `assert_file_mode`               | Asserts the file permission mode                       |
| `assert_binary_files_equal`      | Asserts that two binary files are equal                |
| `assert_binary_files_not_equal`  | Asserts that two binary files are not equal            |

## Directories and symlinks

| Function Name                    | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `assert_dir_exists`              | Asserts that a directory exists                        |
| `assert_dir_not_exists`          | Asserts that a directory does not exist                |
| `assert_dir_empty`               | Asserts that a directory is empty                      |
| `assert_dir_not_empty`           | Asserts that a directory is not empty                  |
| `assert_dir_contains_string`     | Asserts that a directory contains a string in one of its files |
| `assert_dir_not_contains_string` | Asserts that a directory does not contain a string in any of its files |
| `assert_dir_matches`             | Asserts that a file of a directory matches a regular expression |
| `assert_dir_not_matches`         | Asserts that no file of a directory matches a regular expression |
| `assert_dirs_equal`              | Asserts that two directories are equal                 |
| `assert_symlink_exists`          | Asserts that a symbolic link exists                    |
| `assert_symlink_not_exists`      | Asserts that a symbolic link does not exist            |

The six file `contains`, `matches` and `matches_format` assertions and the four directory `contains_string` and `matches` assertions each have a `_case` twin that matches case-sensitively - `assert_file_contains_case`, `assert_dir_matches_case` and so on. See [Match modes](match-modes.md).

| Variable                          | Read by                                                               | Description                                                                             |
|-----------------------------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `BATS_HELPERS_ASSERT_DIR_EXCLUDE` | `assert_dir_contains_string`, `assert_dir_matches` and their variants | Array of directory names to exclude from the search, on top of the always-excluded four |

## Globs

`assert_file_exists` and `assert_file_not_exists` accept a glob. Only the first match decides the outcome, and the failure is reported once however many paths the glob expands to:

```bash
assert_file_exists "${dir}/*.txt"
assert_file_not_exists "${dir}/*.rtf"
```

## Comparing files

`assert_files_equal_ignore_spaces` and `assert_files_not_equal_ignore_spaces` compare two text files ignoring blank lines and whitespace changes:

```bash
assert_files_equal_ignore_spaces "${file1}" "${file2}"
assert_files_not_equal_ignore_spaces "${file1}" "${file2}"
```

## Searching a directory

`assert_dir_contains_string` and `assert_dir_not_contains_string` read the string as a literal substring, and `assert_dir_matches` and `assert_dir_not_matches` read it as an extended regular expression; all four ignore case and have the usual `_case` twins - see [Match modes](match-modes.md). The contents of each file are matched as one string, so a needle may span lines and `^` and `$` anchor to the whole file. The search is recursive over regular files, skips binary files, and always excludes `.git`, `.idea`, `vendor` and `node_modules`; a failed negated assertion lists the matching files in a `files` row of its report. Set `BATS_HELPERS_ASSERT_DIR_EXCLUDE` to an array of additional directory names to exclude:

```bash
declare -a BATS_HELPERS_ASSERT_DIR_EXCLUDE=("build" "dist")
assert_dir_contains_string "${dir}" "needle"
assert_dir_matches "${dir}" 'TODO|FIXME'
```
