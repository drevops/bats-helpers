#!/usr/bin/env bats
#
# Tests for Bats helpers.
#
# Each assertion tests positive and negative behaviour.
#
# shellcheck disable=SC2129

load _test_helper

@test "assert_file_exists" {
  assert_file_exists "${BATS_TEST_FILENAME}"

  mktouch "${BATS_TEST_TMPDIR}/file1.txt"
  mktouch "${BATS_TEST_TMPDIR}/file2.txt"
  mktouch "${BATS_TEST_TMPDIR}/file3.md"
  mktouch "${BATS_TEST_TMPDIR}/a.b.c.d.doc"

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

  mktouch "${BATS_TEST_TMPDIR}/file1.txt"
  mktouch "${BATS_TEST_TMPDIR}/file2.txt"
  mktouch "${BATS_TEST_TMPDIR}/file3.md"

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
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture_symlink"

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
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture_symlink"

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
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture_mode"
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

  run assert_file_mode "${BATS_TEST_TMPDIR}/fixture_mode/1.txt" "644"
  assert_failure
}

@test "assert_file_contains" {
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "some existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "other existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "one more line of existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some existing text"

  run assert_file_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "other non-existing text"
  assert_failure
}

@test "assert_file_not_contains" {
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture_file_assert"
  echo "some existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "other existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"
  echo "one more line of existing text" >>"${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "other non-existing text"

  run assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/1.txt" "some existing text"
  assert_failure

  # Text exists, non-existing file.
  assert_file_not_contains "${BATS_TEST_TMPDIR}/fixture_file_assert/somefile.txt" "some existing text"
}

@test "assert_dir_empty" {
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture/dir1"
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture/dir2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/dir2/1.txt"

  assert_dir_empty "${BATS_TEST_TMPDIR}/fixture/dir1"

  run assert_dir_empty "${BATS_TEST_TMPDIR}/fixture/dir2"
  assert_failure

  run assert_dir_empty "${BATS_TEST_TMPDIR}/non_existing"
  assert_failure
}

@test "assert_dir_not_empty" {
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture/dir1"
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture/dir2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/dir2/1.txt"

  assert_dir_not_empty "${BATS_TEST_TMPDIR}/fixture/dir2"

  run assert_dir_not_empty "${BATS_TEST_TMPDIR}/fixture/dir1"
  assert_failure

  run assert_dir_not_empty "${BATS_TEST_TMPDIR}/non_existing"
  assert_failure
}

@test "assert_dir_contains_string" {
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/1.txt"

  assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"

  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "non-existing"
  assert_failure

  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/non_existing"
  assert_failure

  # Excluded dir.
  rm "${BATS_TEST_TMPDIR}/fixture/1.txt" >/dev/null
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor/2.txt"

  run assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"
  assert_failure
}

@test "assert_dir_not_contains_string" {
  prepare_fixture_dir "${BATS_TEST_TMPDIR}/fixture"
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

  # Excluded dir.
  rm "${BATS_TEST_TMPDIR}/fixture/1.txt" >/dev/null
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/scripts/vendor"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor/2.txt"

  assert_dir_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing"
}

@test "assert_files_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture1_newline.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture2.txt" "${BATS_TEST_TMPDIR}/fixture2.txt"

  assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture2.txt"
  assert_failure
  assert_output_contains "< Third line"
  assert_output_contains "> Third line changed"

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt"
  assert_failure
  assert_output_contains "<"

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture3.txt" "${BATS_TEST_TMPDIR}/fixture4.txt"
  assert_failure

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture3.txt"
  assert_failure

  # Same as above, but ignoring whitespace.
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture1_newline.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture2.txt" "${BATS_TEST_TMPDIR}/fixture2.txt"

  assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"
  assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt" 1

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture2.txt"
  assert_failure
  assert_output_contains "< Third line"
  assert_output_contains "> Third line changed"

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture3.txt" "${BATS_TEST_TMPDIR}/fixture4.txt"
  assert_failure

  run assert_files_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture3.txt"
  assert_failure
}

@test "assert_files_not_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture1_newline.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture2.txt" "${BATS_TEST_TMPDIR}/fixture2.txt"

  assert_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture2.txt"
  assert_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"
  assert_failure
  assert_output_not_contains "< Third line"
  assert_output_not_contains "> Third line changed"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture1_newline.txt" 1
  assert_failure
  assert_output_not_contains "<"

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/fixture3.txt" "${BATS_TEST_TMPDIR}/fixture1.txt"
  assert_failure

  run assert_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.txt" "${BATS_TEST_TMPDIR}/fixture3.txt"
  assert_failure

  # Same as above, but ignoring whitespace.
}

@test "assert_binary_files_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/fixture1.png"
  echo "some other file" >"${BATS_TEST_TMPDIR}/fixture2.png"

  assert_binary_files_equal "${BATS_TEST_TMPDIR}/fixture1.png" "${BATS_TEST_TMPDIR}/fixture1.png"

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/fixture1.png" "${BATS_TEST_TMPDIR}/fixture2.png"
  assert_failure

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/fixture3.png" "${BATS_TEST_TMPDIR}/fixture4.png"
  assert_failure

  run assert_binary_files_equal "${BATS_TEST_TMPDIR}/fixture1.png" "${BATS_TEST_TMPDIR}/fixture3.png"
  assert_failure
}

@test "assert_binary_files_not_equal" {
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/fixture1.png"
  echo "some other file" >"${BATS_TEST_TMPDIR}/fixture2.png"

  assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.png" "${BATS_TEST_TMPDIR}/fixture2.png"

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.png" "${BATS_TEST_TMPDIR}/fixture1.png"
  assert_failure

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/fixture3.png" "${BATS_TEST_TMPDIR}/fixture1.png"
  assert_failure

  run assert_binary_files_not_equal "${BATS_TEST_TMPDIR}/fixture1.png" "${BATS_TEST_TMPDIR}/fixture3.png"
  assert_failure
}

@test "assert_dirs_equal" {
  # Assert that files in the root are equal.
  mkdir -p "${BATS_TEST_TMPDIR}/t11"
  mkdir -p "${BATS_TEST_TMPDIR}/t12"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t11/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t12/fixture1.png"
  assert_dirs_equal "${BATS_TEST_TMPDIR}/t11" "${BATS_TEST_TMPDIR}/t12"

  # Assert that files in the root are not equal.
  echo "some other file" >"${BATS_TEST_TMPDIR}/t12/fixture1.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t11" "${BATS_TEST_TMPDIR}/t12"
  assert_failure

  # Assert that files in the subdirs are equal.
  mkdir -p "${BATS_TEST_TMPDIR}/t31/subdir"
  mkdir -p "${BATS_TEST_TMPDIR}/t32/subdir"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t31/subdir/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t32/subdir/fixture1.png"
  assert_dirs_equal "${BATS_TEST_TMPDIR}/t31" "${BATS_TEST_TMPDIR}/t32"

  # Assert that files in the subdirs are not equal.
  echo "some other file" >"${BATS_TEST_TMPDIR}/t32/subdir/fixture1.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t31" "${BATS_TEST_TMPDIR}/t32"
  assert_failure

  # Assert that files in the root and subdirs are equal.
  mkdir -p "${BATS_TEST_TMPDIR}/t41/subdir"
  mkdir -p "${BATS_TEST_TMPDIR}/t42/subdir"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t41/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t41/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t41/subdir/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t42/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t42/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t42/subdir/fixture1.png"
  assert_dirs_equal "${BATS_TEST_TMPDIR}/t41" "${BATS_TEST_TMPDIR}/t42"

  # Assert that files in the root and subdirs are not equal.
  echo "some other file" >"${BATS_TEST_TMPDIR}/t42/subdir/fixture1.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t41" "${BATS_TEST_TMPDIR}/t42"
  assert_failure

  # Assert that missing files trigger a failure.
  mkdir -p "${BATS_TEST_TMPDIR}/t51/subdir"
  mkdir -p "${BATS_TEST_TMPDIR}/t52/subdir"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t51/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t51/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t51/subdir/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t51/subdir/fixture2.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t52/fixture1.png"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t52/.hidden"
  cp "${BATS_TEST_DIRNAME}/fixtures/fixture.png" "${BATS_TEST_TMPDIR}/t52/subdir/fixture1.png"
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t51" "${BATS_TEST_TMPDIR}/t52"
  assert_failure

  # Assert non-existing dirs are failing.
  run assert_dirs_equal "${BATS_TEST_TMPDIR}/t61" "${BATS_TEST_TMPDIR}/t62"
  assert_failure
}

@test "mktouch" {
  assert_file_not_exists "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
  mktouch "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
  assert_file_exists "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
}

@test "read_env" {
  pushd "${BATS_TEST_TMPDIR}"

  assert_file_not_exists ".env"

  echo "VAR1=val1" >>.env
  echo "VAR2=val2" >>.env
  # shellcheck disable=SC2016
  run read_env '$VAR1'
  assert_output_contains "val1"
  # shellcheck disable=SC2016
  run read_env '$VAR2'
  assert_output_contains "val2"

  popd
}

@test "trim_file" {
  echo "line1" >>"${BATS_TEST_TMPDIR}/file.txt"
  echo "line2" >>"${BATS_TEST_TMPDIR}/file.txt"
  echo "line3" >>"${BATS_TEST_TMPDIR}/file.txt"

  trim_file "${BATS_TEST_TMPDIR}/file.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/file.txt" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/file.txt" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line3"

  trim_file "${BATS_TEST_TMPDIR}/file.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/file.txt" "line1"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line3"
}

@test "add_var_to_file and restore_file" {
  rm -fr /tmp/bkp

  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"
  echo "line2" >>"${BATS_TEST_TMPDIR}/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/.env" "VAR" "value"

  assert_file_exists "${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"

  assert_file_exists "/tmp/bkp/${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "/tmp/bkp/${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "/tmp/bkp/${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_not_contains "/tmp/bkp/${BATS_TEST_TMPDIR}/.env" "VAR=value"

  restore_file "${BATS_TEST_TMPDIR}/.env"

  assert_file_exists "${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
}
