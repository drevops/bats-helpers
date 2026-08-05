# Fixtures

Building, dumping and asserting the file trees a test runs against.

Source: [`src/fixture.bash`](../src/fixture.bash)

| Function Name             | Description                                                                |
|---------------------------|----------------------------------------------------------------------------|
| `fixture_prepare_dir`     | Creates an empty directory for a fixture, removing any existing content    |
| `fixture_export_codebase` | Exports the codebase at the latest commit to a destination directory       |
| `fixture_create_dir`      | Creates a file tree from an archive read from STDIN                        |
| `fixture_dump_dir`        | Prints a directory as an archive                                           |
| `fixture_assert_dir`      | Asserts that a directory holds the file tree of an archive read from STDIN |

`fixture_export_codebase` is a no-op unless `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED` is set to `1`, so an expensive export can be enabled per suite rather than per call:

```bash
export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
```

## Fixture trees

`fixture_create_dir` builds a whole file tree from a plain-text archive read from STDIN, so the shape of the fixture is visible in the test rather than reconstructed from a run of `mkdir` and `echo` calls. Fed from a quoted here-document, the content passes through byte for byte: nothing is expanded, and nothing needs escaping apart from a line that would itself read as a marker:

```bash
fixture_create_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project

-- src/app.sh --
#!/usr/bin/env bash
echo "value is ${UNEXPANDED}"

-- config/.env --
FOO=bar
FIXTURE
```

A line is a marker when it opens with `--` followed by a space and closes with a space followed by `--`; the name between them is trimmed, so markers can be padded to line up. After the first marker, every line that is not itself a marker is content, which is what makes the format safe to hand-edit: there is nothing to get syntactically wrong. An entry holds every line from its marker to the next marker or to the end of the archive, and parent directories are created implicitly.

Anything before the first marker is a comment and is discarded, so a fixture can carry a note about what it stands for:

```bash
fixture_create_dir "${dir}" <<'FIXTURE'
The tree the installer expects to find before it runs.

-- config/.env --
FOO=bar
FIXTURE
```

The directory is created when it does not exist, and only the files the archive names are written. Pair the call with `fixture_prepare_dir` to start from an empty directory:

```bash
fixture_prepare_dir "${dir}"
fixture_create_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
FIXTURE
```

A content line that would otherwise be read as a marker carries one leading backslash. Reading removes one backslash from a line that is marker-shaped without it, so `\-- README.md --` is the content `-- README.md --`, and `\\-- README.md --` is the content `\-- README.md --`. A backslash anywhere else is left alone.

An archive path is a plain relative path naming a file. An absolute path, a `..`, `.` or empty component, a trailing slash, a marker naming nothing, and a path declared twice are each rejected with a message naming the path. `fixture_create_dir` also refuses to write through a symlink already sitting on the path, so a link an earlier fixture or the code under test left behind cannot carry the write outside the directory.

`fixture_dump_dir` prints an existing directory in the same format, ordered by path. It is both a debugging aid - dump what the code under test actually produced and paste it back into the test - and the way to regenerate an expectation:

```bash
run fixture_dump_dir "${dir}"
assert_success
```

`fixture_assert_dir` compares a directory against an inline expected tree:

```bash
fixture_assert_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
-- src/app.sh --
#!/usr/bin/env bash
FIXTURE
```

A mismatch lists every file that is missing, unexpected or different, and appends a unified diff for each differing file:

```text
-- Directory does not match the expected fixture --
directory (1 line):
${BATS_TEST_TMPDIR}/build
summary (3 lines):
differs: src/app.sh
missing: src/missing.sh
unexpected: src/extra.sh
difference (5 lines):
--- expected src/app.sh
+++ actual src/app.sh
@@ -1 +1 @@
-#!/usr/bin/env bash
+#!/bin/sh
--
```

The format covers text files and nothing else. Binary content, file modes and symlinks are deliberately out of scope - `assert_file_mode`, `file_mktouch` and `ln -s` remain the way to handle those - and `fixture_dump_dir` serialises regular files only, failing on a file that is not text. `fixture_assert_dir` compares regular files only for the same reason: a symlink standing where the archive names a file is reported as a difference, and one the archive says nothing about is left alone. Because the format is line-based, every file it names ends with a newline: `fixture_dump_dir` adds one to a file that lacks it, and `fixture_assert_dir` compares bytes, so a file with no trailing newline differs from the archive that names it.
