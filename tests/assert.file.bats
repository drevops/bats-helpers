#!/usr/bin/env bats
#
# Tests for file and directory assertions.
#
# shellcheck disable=SC2129,SC2030,SC2031,SC2034

load _test_helper

@test "assert_file_exists" {
  assert_file_exists "${BATS_TEST_FILENAME}"

  file_mktouch "${BATS_TEST_TMPDIR}/file1.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/file2.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/file3.md"
  file_mktouch "${BATS_TEST_TMPDIR}/a.b.c.d.doc"

  assert_file_exists "${BATS_TEST_TMPDIR}/file1.txt"
  assert_file_exists "${BATS_TEST_TMPDIR}/file2.txt"
  assert_file_exists "${BATS_TEST_TMPDIR}/file3.md"

  assert_file_exists "${BATS_TEST_TMPDIR}/file*"
  assert_file_exists "${BATS_TEST_TMPDIR}/*.txt"
  assert_file_exists "${BATS_TEST_TMPDIR}/*.doc"

  run assert_file_exists "some_file.txt"
  assert_failure

  run assert_file_exists "${BATS_TEST_TMPDIR}/*.rtf"
  assert_failure

  run assert_file_exists "${BATS_TEST_TMPDIR}/other*"
  assert_failure
}

@test "assert_file_not_exists" {
  assert_file_not_exists "some_file.txt"

  file_mktouch "${BATS_TEST_TMPDIR}/file1.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/file2.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/file3.md"

  assert_file_not_exists "${BATS_TEST_TMPDIR}/otherfile1.txt"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/otherfile*"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/*.rtf"

  run assert_file_not_exists "${BATS_TEST_FILENAME}"
  assert_failure

  run assert_file_not_exists "${BATS_TEST_TMPDIR}/file1.txt"
  assert_failure

  run assert_file_not_exists "${BATS_TEST_TMPDIR}/file*"
  assert_failure

  run assert_file_not_exists "${BATS_TEST_TMPDIR}/*.txt"
  assert_failure
}

@test "assert_file_exists reports a failure once" {
  run assert_file_exists "${BATS_TEST_TMPDIR}/missing.txt"
  assert_failure

  banner_count="$(echo "${output}" | grep -c "BEGIN ERROR MESSAGE" || true)"
  assert_equal "1" "${banner_count}"
}

@test "assert_file_not_exists reports a failure once for a glob" {
  file_mktouch "${BATS_TEST_TMPDIR}/file1.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/file2.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/file3.txt"

  run assert_file_not_exists "${BATS_TEST_TMPDIR}/*.txt"
  assert_failure

  banner_count="$(echo "${output}" | grep -c "BEGIN ERROR MESSAGE" || true)"
  assert_equal "1" "${banner_count}"
}

@test "assert_dir_exists" {
  assert_dir_exists "${BATS_TEST_DIRNAME}"

  run assert_dir_exists "some dir"
  assert_failure
}

@test "assert_dir_not_exists" {
  assert_dir_not_exists "some dir"

  run assert_dir_not_exists "${BATS_TEST_DIRNAME}"
  assert_failure
}

@test "assert_symlink_exists" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_symlink"

  # Assert file.
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture_symlink/src.txt"
  ln -s "${BATS_TEST_TMPDIR}/fixture_symlink/src.txt" "${BATS_TEST_TMPDIR}/fixture_symlink/dst.txt"
  assert_symlink_exists "${BATS_TEST_TMPDIR}/fixture_symlink/dst.txt"

  run assert_symlink_exists "${BATS_TEST_TMPDIR}/fixture_symlink/not-existing.txt"
  assert_failure

  # Assert dir.
  mkdir "${BATS_TEST_TMPDIR}/fixture_symlink/symlink_src"
  ln -s "${BATS_TEST_TMPDIR}/fixture_symlink/symlink_src" "${BATS_TEST_TMPDIR}/fixture_symlink/symlink_dst"
  assert_symlink_exists "${BATS_TEST_TMPDIR}/fixture_symlink/symlink_dst"
  run assert_symlink_exists "${BATS_TEST_TMPDIR}/fixture_symlink/symlink_dst_not_exisitng"
  assert_failure
}

@test "assert_symlink_not_exists" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_symlink"

  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture_symlink/src.txt"
  ln -s "${BATS_TEST_TMPDIR}/fixture_symlink/src.txt" "${BATS_TEST_TMPDIR}/fixture_symlink/dst.txt"

  # Assert others.
  assert_symlink_not_exists "${BATS_TEST_TMPDIR}/fixture_symlink/src.txt"
  assert_symlink_not_exists "${BATS_TEST_TMPDIR}/fixture_symlink/other_dst.txt"
  assert_symlink_not_exists "${BATS_TEST_TMPDIR}/fixture_symlink/some_dir"

  run assert_symlink_not_exists "${BATS_TEST_TMPDIR}/fixture_symlink/dst.txt"
  assert_failure
}

@test "assert_file_mode" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_mode"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture_mode/1.txt"
  chmod 644 "${BATS_TEST_TMPDIR}/fixture_mode/1.txt"
  assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "644"
  chmod 664 "${BATS_TEST_TMPDIR}/fixture_mode/1.txt"
  assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "644"
  chmod 755 "${BATS_TEST_TMPDIR}/fixture_mode/1.txt"
  assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "755"
  chmod 775 "${BATS_TEST_TMPDIR}/fixture_mode/1.txt"
  assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "755"
  chmod 777 "${BATS_TEST_TMPDIR}/fixture_mode/1.txt"
  assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "755"

  run assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/non_existing.txt" "644"
  assert_failure
  assert_output_contains "does not exist"
  assert_output_not_contains "has permissions"

  run assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "644"
  assert_failure
}

@test "assert_file_contains" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "some existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "other existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "one more line of existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some existing text"
  assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some EXISTING text"

  run assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/non_existing.txt" "some existing text"
  assert_failure
  assert_output_contains "does not exist"
  assert_output_not_contains "does not contain"

  run assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "other non-existing text"
  assert_failure

  run assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  assert_failure
  assert_output_contains "A file and a string are required."

  # Only a regular file has contents to read.
  run assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert" "some existing text"
  assert_failure
  assert_output_contains "is not a regular file"

  run assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/*.txt" "some existing text"
  assert_failure
  assert_output_contains "is not a regular file"
}

@test "assert_file_contains_case" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "some existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some existing text"

  run assert_file_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some EXISTING text"
  assert_failure

  run assert_file_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/non_existing.txt" "some existing text"
  assert_failure
  assert_output_contains "does not exist"
}

@test "assert_file_not_contains" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "some existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "other existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "one more line of existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "other non-existing text"

  run assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some existing text"
  assert_failure

  run assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some EXISTING text"
  assert_failure

  # Text exists, non-existing file.
  assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" "some existing text"
}

@test "assert_file_not_contains_case" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "some existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "other non-existing text"
  assert_file_not_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some EXISTING text"

  # Text exists, non-existing file.
  assert_file_not_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" "some existing text"

  run assert_file_not_contains_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some existing text"
  assert_failure
}

@test "assert_file_matches" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Deleted [0-9]+ files'
  assert_file_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'DELETED [0-9]+ files'

  run assert_file_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/non_existing.txt" 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "does not exist"

  run assert_file_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Removed [0-9]+ files'
  assert_failure
}

@test "assert_file_matches_case" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Deleted [0-9]+ files'

  run assert_file_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'DELETED [0-9]+ files'
  assert_failure

  run assert_file_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/non_existing.txt" 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "does not exist"
}

@test "assert_file_not_matches" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Removed [0-9]+ files'

  # A file that does not exist cannot match.
  assert_file_not_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" 'Deleted [0-9]+ files'

  run assert_file_not_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Deleted [0-9]+ files'
  assert_failure

  run assert_file_not_matches "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'DELETED [0-9]+ files'
  assert_failure
}

@test "assert_file_not_matches_case" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Removed [0-9]+ files'
  assert_file_not_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'DELETED [0-9]+ files'

  # A file that does not exist cannot match.
  assert_file_not_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" 'Deleted [0-9]+ files'

  run assert_file_not_matches_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" 'Deleted [0-9]+ files'
  assert_failure
}

@test "assert_file_matches_format" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Deleted %d files in %fs"
  assert_file_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "DELETED %d files"

  run assert_file_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/non_existing.txt" "Deleted %d files"
  assert_failure
  assert_output_contains "does not exist"

  run assert_file_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Removed %d files"
  assert_failure
}

@test "assert_file_matches_format_case" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Deleted %d files"

  run assert_file_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "DELETED %d files"
  assert_failure

  run assert_file_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/non_existing.txt" "Deleted %d files"
  assert_failure
  assert_output_contains "does not exist"
}

@test "assert_file_not_matches_format" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Removed %d files"

  # A file that does not exist cannot match.
  assert_file_not_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" "Deleted %d files"

  run assert_file_not_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Deleted %d files"
  assert_failure

  run assert_file_not_matches_format "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "DELETED %d files"
  assert_failure
}

@test "assert_file_not_matches_format_case" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "Deleted 12 files in 0.5s" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Removed %d files"
  assert_file_not_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "DELETED %d files"

  # A file that does not exist cannot match.
  assert_file_not_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" "Deleted %d files"

  run assert_file_not_matches_format_case "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "Deleted %d files"
  assert_failure
}

@test "assert_dir_empty" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/dir1"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/dir2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/dir2/1.txt"

  assert_dir_empty "${BATS_TEST_TMPDIR}/fixture/dir1"

  run assert_dir_empty "${BATS_TEST_TMPDIR}/fixture/dir2"
  assert_failure

  run assert_dir_empty "${BATS_TEST_TMPDIR}/non_existing"
  assert_failure
}

@test "assert_dir_not_empty" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/dir1"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/dir2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/dir2/1.txt"

  assert_dir_not_empty "${BATS_TEST_TMPDIR}/fixture/dir2"

  run assert_dir_not_empty "${BATS_TEST_TMPDIR}/non_existing"
  assert_failure
  assert_output_contains "does not exist"
  assert_output_not_contains "is empty, but should not be"

  run assert_dir_not_empty "${BATS_TEST_TMPDIR}/fixture/dir1"
  assert_failure
}

@test "assert_dir_contains_string" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/1.txt"

  assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"

  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "non-existing"
  assert_failure

  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/non_existing"
  assert_failure

  rm "${BATS_TEST_TMPDIR}/fixture/1.txt" >/dev/null

  # Excluded dir.
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor/2.txt"
  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"
  assert_failure

  # Globally excluded dir.
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor2/2.txt"
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor three"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor three/2.txt"
  declare -a BATS_HELPERS_ASSERT_DIR_EXCLUDE=(vendor2 "vendor three")
  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"
  assert_failure
}

@test "assert_dir_not_contains_string" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/1.txt"
  echo "some other text" >"${BATS_TEST_TMPDIR}/fixture/2.txt"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/3.txt"

  assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/fixture" "non-existing"

  run assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"
  assert_failure
  assert_output_contains "fixture/1.txt"
  assert_output_contains "fixture/3.txt"
  assert_output_not_contains "fixture/2.txt"

  # Non-existing dir.
  assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/non_existing" "existing"

  rm "${BATS_TEST_TMPDIR}/fixture/1.txt" >/dev/null
  rm "${BATS_TEST_TMPDIR}/fixture/2.txt" >/dev/null
  rm "${BATS_TEST_TMPDIR}/fixture/3.txt" >/dev/null

  # Excluded dir.
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor/2.txt"
  assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"

  # Globally excluded dir.
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor2/2.txt"
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor three"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor three/2.txt"
  declare -a BATS_HELPERS_ASSERT_DIR_EXCLUDE=(vendor2 "vendor three")
  assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"
}

@test "assert_files_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_newline.txt" "${BATS_TEST_TMPDIR}/text_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_changed.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"

  assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text.txt"

  run assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"
  assert_failure
  assert_output_contains "difference (4 lines):"
  assert_output_contains "< Third line"
  assert_output_contains "> Third line changed"

  run assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_newline.txt"
  assert_failure
  assert_output_contains "-- Files are not equal --"

  run assert_files_equal "${BATS_TEST_TMPDIR}/missing.txt" "${BATS_TEST_TMPDIR}/missing_other.txt"
  assert_failure

  run assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/missing.txt"
  assert_failure

  # Same as above, but ignoring whitespace.
  cp "${BATS_TEST_DIRNAME}/fixtures/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_newline.txt" "${BATS_TEST_TMPDIR}/text_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_changed.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"

  assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_newline.txt" 1

  run assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"
  assert_failure
  assert_output_contains "< Third line"
  assert_output_contains "> Third line changed"

  run assert_files_equal "${BATS_TEST_TMPDIR}/missing.txt" "${BATS_TEST_TMPDIR}/missing_other.txt"
  assert_failure

  run assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/missing.txt"
  assert_failure
}

@test "assert_files_not_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_newline.txt" "${BATS_TEST_TMPDIR}/text_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_changed.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"

  assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"
  assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_newline.txt"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  assert_failure
  assert_output_not_contains "< Third line"
  assert_output_not_contains "> Third line changed"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_newline.txt" 1
  assert_failure
  assert_output_not_contains "<"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/missing.txt" "${BATS_TEST_TMPDIR}/text.txt"
  assert_failure

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/missing.txt"
  assert_failure
}

@test "assert_binary_files_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/binary.png"
  echo "some other file" >"${BATS_TEST_TMPDIR}/binary_changed.png"

  assert_binary_files_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/binary.png"

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/binary_changed.png"
  assert_failure

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/missing.png" "${BATS_TEST_TMPDIR}/missing_other.png"
  assert_failure

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/missing.png"
  assert_failure
}

@test "assert_binary_files_not_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/binary.png"
  echo "some other file" >"${BATS_TEST_TMPDIR}/binary_changed.png"

  assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/binary_changed.png"

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/binary.png"
  assert_failure

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/missing.png" "${BATS_TEST_TMPDIR}/binary.png"
  assert_failure

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/missing.png"
  assert_failure
}

# A directory passes the existence check the comparisons make first, so it is
# what reaches 'diff' and 'cmp' as an operand they cannot read.
@test "A comparison that could not run is an error rather than a difference" {
  cp "${BATS_TEST_DIRNAME}/fixtures/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/binary.png"
  mkdir -p "${BATS_TEST_TMPDIR}/empty-dir"

  run assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/empty-dir"
  assert_failure
  assert_output_contains "Unable to compare the files:"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/empty-dir"
  assert_failure
  assert_output_contains "Unable to compare the files:"

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/empty-dir"
  assert_failure
  assert_output_contains "Unable to compare the files:"

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/binary.png" "${BATS_TEST_TMPDIR}/empty-dir"
  assert_failure
  assert_output_contains "Unable to compare the files:"
}

@test "assert_dirs_equal" {
  # Assert that files in the root are equal.
  mkdir -p "${BATS_TEST_TMPDIR}/t11"
  mkdir -p "${BATS_TEST_TMPDIR}/t12"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t11/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t12/binary.png"
  assert_dirs_equal "${BATS_TEST_TMPDIR}/t11" "${BATS_TEST_TMPDIR}/t12"

  # Assert that files in the root are not equal.
  echo "some other file" >"${BATS_TEST_TMPDIR}/t12/binary.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t11" "${BATS_TEST_TMPDIR}/t12"
  assert_failure

  # Assert that files in the subdirs are equal.
  mkdir -p "${BATS_TEST_TMPDIR}/t31/subdir"
  mkdir -p "${BATS_TEST_TMPDIR}/t32/subdir"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t31/subdir/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t32/subdir/binary.png"
  assert_dirs_equal "${BATS_TEST_TMPDIR}/t31" "${BATS_TEST_TMPDIR}/t32"

  # Assert that files in the subdirs are not equal.
  echo "some other file" >"${BATS_TEST_TMPDIR}/t32/subdir/binary.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t31" "${BATS_TEST_TMPDIR}/t32"
  assert_failure

  # Assert that files in the root and subdirs are equal.
  mkdir -p "${BATS_TEST_TMPDIR}/t41/subdir"
  mkdir -p "${BATS_TEST_TMPDIR}/t42/subdir"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t41/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t41/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t41/subdir/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t42/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t42/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t42/subdir/binary.png"
  assert_dirs_equal "${BATS_TEST_TMPDIR}/t41" "${BATS_TEST_TMPDIR}/t42"

  # Assert that files in the root and subdirs are not equal.
  echo "some other file" >"${BATS_TEST_TMPDIR}/t42/subdir/binary.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t41" "${BATS_TEST_TMPDIR}/t42"
  assert_failure

  # Assert that missing files trigger a failure.
  mkdir -p "${BATS_TEST_TMPDIR}/t51/subdir"
  mkdir -p "${BATS_TEST_TMPDIR}/t52/subdir"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t51/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t51/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t51/subdir/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t51/subdir/binary_extra.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t52/binary.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t52/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/binary.png" "${BATS_TEST_TMPDIR}/t52/subdir/binary.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t51" "${BATS_TEST_TMPDIR}/t52"
  assert_failure

  # Assert non-existing dirs are failing.
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t61" "${BATS_TEST_TMPDIR}/t62"
  assert_failure
}
