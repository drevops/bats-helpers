#!/usr/bin/env bats
#
# Tests for fixture helpers.
#
# shellcheck disable=SC2030,SC2031,SC2016

load _test_helper

@test "Codebase export not enabled" {
  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"
  fixture_export_codebase "${build_dir}"
  assert_file_not_exists "${build_dir}/README.md"
}

@test "Codebase export enabled" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"
  fixture_export_codebase "${build_dir}"
  assert_file_exists "${build_dir}/README.md"
}

@test "Codebase export - missing destination directory" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/non-existing"

  run fixture_export_codebase "${build_dir}"
  assert_failure
  # 'flunk' rewrites the temporary directory path to a literal placeholder.
  assert_output_contains '-- Directory does not exist --
directory : ${BATS_TEST_TMPDIR}/non-existing
--'
}

@test "Codebase export - missing destination directory - caller recovers" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/non-existing"

  recovered=0
  fixture_export_codebase "${build_dir}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Codebase export - export fails" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  # A repository without commits has no HEAD, so 'git archive' fails.
  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-no-commits"
  fixture_prepare_dir "${src_dir}"
  git -C "${src_dir}" init --quiet

  run fixture_export_codebase "${build_dir}" "${src_dir}"
  assert_failure
  assert_output_contains "Unable to export codebase"
}

@test "Codebase export - export fails - caller recovers" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-no-commits"
  fixture_prepare_dir "${src_dir}"
  git -C "${src_dir}" init --quiet

  recovered=0
  fixture_export_codebase "${build_dir}" "${src_dir}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Codebase export - source is not a git repository" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-not-a-repo"
  fixture_prepare_dir "${src_dir}"

  run fixture_export_codebase "${build_dir}" "${src_dir}"
  assert_failure
  # 'flunk' rewrites the temporary directory path to a literal placeholder.
  assert_output_contains '-- Directory is not a git repository --
directory : ${BATS_TEST_TMPDIR}/src-not-a-repo
--'
}

@test "Codebase export - source is not a git repository - caller recovers" {
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-not-a-repo"
  fixture_prepare_dir "${src_dir}"

  recovered=0
  fixture_export_codebase "${build_dir}" "${src_dir}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "fixture_create_dir" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
Everything before the first marker annotates the fixture and is discarded.

-- README.md --
# Project
-- src/app.sh --
#!/usr/bin/env bash
echo "one"
-- config/nested/.env --
FOO=bar
FIXTURE

  assert_file_contains "${dir}/README.md" "# Project"
  assert_file_contains "${dir}/src/app.sh" 'echo "one"'
  assert_file_contains "${dir}/config/nested/.env" "FOO=bar"
  assert_file_not_contains "${dir}/README.md" "annotates"
}

@test "fixture_create_dir preserves the content verbatim" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- src/app.sh --
#!/usr/bin/env bash
# A hash, a $dollar and a `backtick`.
echo "value is ${UNEXPANDED}"
printf '%s\n' 'single'"double"
FIXTURE

  run cat "${dir}/src/app.sh"
  assert_success
  assert_output <<'EXPECTED'
#!/usr/bin/env bash
# A hash, a $dollar and a `backtick`.
echo "value is ${UNEXPANDED}"
printf '%s\n' 'single'"double"
EXPECTED
}

@test "fixture_create_dir with an empty entry" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- empty.txt --
-- other.txt --
content
FIXTURE

  assert_file_exists "${dir}/empty.txt"

  run cat "${dir}/empty.txt"
  assert_success
  assert_output ""

  assert_file_contains "${dir}/other.txt" "content"
}

@test "fixture_create_dir trims the marker name" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
--   src/app.sh   --
one
FIXTURE

  assert_file_contains "${dir}/src/app.sh" "one"
}

@test "fixture_create_dir with an escaped marker line" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- doc.md --
An archive looks like this:
\-- README.md --
# Project
\\-- nested --
\keep the backslash
FIXTURE

  run cat "${dir}/doc.md"
  assert_success
  assert_output <<'EXPECTED'
An archive looks like this:
-- README.md --
# Project
\-- nested --
\keep the backslash
EXPECTED
}

@test "fixture_create_dir without a trailing newline" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" < <(printf -- '-- file.txt --\nlast line')

  run cat "${dir}/file.txt"
  assert_success
  assert_output "last line"
}

@test "fixture_create_dir with an empty archive" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" </dev/null

  assert_dir_exists "${dir}"
  assert_dir_empty "${dir}"
}

@test "fixture_create_dir keeps the files it does not name" {
  dir="${BATS_TEST_TMPDIR}/tree"
  file_mktouch "${dir}/keep.txt"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- add.txt --
added
FIXTURE

  assert_file_exists "${dir}/keep.txt"
  assert_file_contains "${dir}/add.txt" "added"
}

@test "fixture_create_dir with an absolute path" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- /etc/passwd --
x
FIXTURE
  assert_failure
  assert_output_contains "Fixture path '/etc/passwd' is absolute"

  # The archive is read before anything is created.
  assert_dir_not_exists "${BATS_TEST_TMPDIR}/tree"
}

@test "fixture_create_dir with a parent directory reference" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- ../escape.txt --
x
FIXTURE
  assert_failure
  assert_output_contains "escapes the fixture directory"
}

@test "fixture_create_dir with a current directory reference" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- ./file.txt --
x
FIXTURE
  assert_failure
  assert_output_contains "contains a '.' component"
}

@test "fixture_create_dir with an empty path component" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- src//app.sh --
x
FIXTURE
  assert_failure
  assert_output_contains "contains an empty component"
}

@test "fixture_create_dir with a symlinked parent" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  mkdir -p "${BATS_TEST_TMPDIR}/outside"
  ln -s "${BATS_TEST_TMPDIR}/outside" "${dir}/src"

  run fixture_create_dir "${dir}" <<'FIXTURE'
-- src/app.sh --
x
FIXTURE
  assert_failure
  assert_output_contains "leads through the symlink"

  assert_file_not_exists "${BATS_TEST_TMPDIR}/outside/app.sh"
}

@test "fixture_create_dir with a symlinked file" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  echo "outside" >"${BATS_TEST_TMPDIR}/outside.txt"
  ln -s "${BATS_TEST_TMPDIR}/outside.txt" "${dir}/app.sh"

  run fixture_create_dir "${dir}" <<'FIXTURE'
-- app.sh --
x
FIXTURE
  assert_failure
  assert_output_contains "leads through the symlink"

  assert_file_contains "${BATS_TEST_TMPDIR}/outside.txt" "outside"
}

@test "fixture_create_dir with a directory path" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- src/ --
x
FIXTURE
  assert_failure
  assert_output_contains "names a directory"
}

@test "fixture_create_dir with an unnamed marker" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
--  --
x
FIXTURE
  assert_failure
  assert_output_contains "does not name a file"
}

@test "fixture_create_dir with a duplicate path" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- file.txt --
one
-- file.txt --
two
FIXTURE
  assert_failure
  assert_output_contains "is declared more than once"
}

@test "fixture_create_dir with a path that is a directory" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- src/app.sh --
one
-- src --
two
FIXTURE
  assert_failure
  assert_output_contains "Fixture path 'src' exists as a directory"
}

@test "fixture_create_dir with a path below a file" {
  run fixture_create_dir "${BATS_TEST_TMPDIR}/tree" <<'FIXTURE'
-- src --
one
-- src/app.sh --
two
FIXTURE
  assert_failure
  assert_output_contains "Unable to create fixture file 'src/app.sh'"
}

@test "fixture_create_dir with an unusable directory" {
  file_mktouch "${BATS_TEST_TMPDIR}/file"

  run fixture_create_dir "${BATS_TEST_TMPDIR}/file/tree" <<'FIXTURE'
-- a.txt --
x
FIXTURE
  assert_failure
  assert_output_contains "Unable to create fixture directory"
}

@test "fixture_dump_dir" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- src/app.sh --
echo "one"
-- .hidden --
hidden
-- README.md --
# Project
FIXTURE

  run fixture_dump_dir "${dir}"
  assert_success
  assert_output <<'EXPECTED'
-- .hidden --
hidden
-- README.md --
# Project
-- src/app.sh --
echo "one"
EXPECTED
}

@test "fixture_dump_dir escapes a marker line" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- doc.md --
An archive looks like this:
\-- README.md --
# Project
\\-- nested --
\keep the backslash
FIXTURE

  run fixture_dump_dir "${dir}"
  assert_success
  assert_output <<'EXPECTED'
-- doc.md --
An archive looks like this:
\-- README.md --
# Project
\\-- nested --
\keep the backslash
EXPECTED
}

@test "fixture_dump_dir adds a trailing newline" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  printf 'no newline' >"${dir}/file.txt"

  run fixture_dump_dir "${dir}"
  assert_success
  assert_output <<'EXPECTED'
-- file.txt --
no newline
EXPECTED
}

@test "fixture_dump_dir with an empty directory" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"

  run fixture_dump_dir "${dir}"
  assert_success
  assert_output ""
}

@test "fixture_dump_dir with a missing directory" {
  run fixture_dump_dir "${BATS_TEST_TMPDIR}/missing"
  assert_failure
  assert_output_contains "does not exist"
}

@test "fixture_dump_dir with a binary file" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  printf 'a\000b\n' >"${dir}/binary.bin"

  run fixture_dump_dir "${dir}"
  assert_failure
  assert_output_contains "Fixture file 'binary.bin' is not a text file"
}

@test "fixture_dump_dir with a newline in a file name" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  touch "${dir}/$(printf 'one\ntwo')"

  run fixture_dump_dir "${dir}"
  assert_failure
  assert_output_contains "contains a newline"
}

@test "fixture_list_files with a directory it cannot walk" {
  run fixture_list_files "${BATS_TEST_TMPDIR}/missing"
  assert_failure
  assert_output_contains "Unable to list the files"
}

@test "fixture_assert_dir" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
-- src/app.sh --
echo "one"
FIXTURE

  fixture_assert_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
-- src/app.sh --
echo "one"
FIXTURE

  run fixture_assert_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
-- src/app.sh --
echo "two"
FIXTURE
  assert_failure
  assert_output_contains "does not match the expected fixture"
  assert_output_contains "differs: src/app.sh"
  assert_output_contains '-echo "two"'
  assert_output_contains '+echo "one"'
}

@test "fixture_assert_dir with a missing file" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
FIXTURE

  run fixture_assert_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
-- src/app.sh --
echo "one"
FIXTURE
  assert_failure
  assert_output_contains "missing: src/app.sh"
}

@test "fixture_assert_dir with an unexpected file" {
  dir="${BATS_TEST_TMPDIR}/tree"

  fixture_create_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
-- src/app.sh --
echo "one"
FIXTURE

  run fixture_assert_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
FIXTURE
  assert_failure
  assert_output_contains "unexpected: src/app.sh"
}

@test "fixture_assert_dir with a file that has no trailing newline" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  printf 'no newline' >"${dir}/file.txt"

  # The archive always names a trailing newline, so a file without one differs.
  run fixture_assert_dir "${dir}" <<'FIXTURE'
-- file.txt --
no newline
FIXTURE
  assert_failure
  assert_output_contains "differs: file.txt"
  assert_output_contains "No newline at end of file"
}

@test "fixture_assert_dir with a symlink in place of a file" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"
  echo "# Project" >"${BATS_TEST_TMPDIR}/outside.md"
  ln -s "${BATS_TEST_TMPDIR}/outside.md" "${dir}/README.md"

  # The content behind the symlink matches, but the directory does not hold the
  # regular file the archive names.
  run fixture_assert_dir "${dir}" <<'FIXTURE'
-- README.md --
# Project
FIXTURE
  assert_failure
  assert_output_contains "not a regular file: README.md"
}

@test "fixture_assert_dir with an empty archive" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"

  fixture_assert_dir "${dir}" </dev/null

  file_mktouch "${dir}/extra.txt"

  run fixture_assert_dir "${dir}" </dev/null
  assert_failure
  assert_output_contains "unexpected: extra.txt"
}

@test "fixture_assert_dir with an invalid archive" {
  dir="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${dir}"

  run fixture_assert_dir "${dir}" <<'FIXTURE'
-- /etc/passwd --
x
FIXTURE
  assert_failure
  assert_output_contains "is absolute"
}

@test "fixture_assert_dir with a missing directory" {
  run fixture_assert_dir "${BATS_TEST_TMPDIR}/missing" </dev/null
  assert_failure
  assert_output_contains "does not exist"
}
