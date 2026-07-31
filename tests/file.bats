#!/usr/bin/env bats
#
# Tests for file utilities.
#
# shellcheck disable=SC2129,SC2030,SC2031

load _test_helper

@test "mktouch" {
  assert_file_not_exists "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
  mktouch "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
  assert_file_exists "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
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

@test "file_backup_path" {
  run file_backup_path "${BATS_TEST_TMPDIR}/.env"
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/bats-helpers-backup/${BATS_TEST_TMPDIR#/}/.env"

  run file_backup_path ".env"
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/bats-helpers-backup/.env"
}

@test "file_backup_path with a custom directory" {
  export BATS_HELPERS_BACKUP_DIR="${BATS_TEST_TMPDIR}/custom"

  run file_backup_path "${BATS_TEST_TMPDIR}/.env"
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/${BATS_TEST_TMPDIR#/}/.env"

  # A trailing slash does not produce a double separator.
  export BATS_HELPERS_BACKUP_DIR="${BATS_TEST_TMPDIR}/custom/"

  run file_backup_path ".env"
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/.env"
}

@test "file_backup_path with a parent directory reference" {
  run file_backup_path "${BATS_TEST_TMPDIR}/../.env"
  assert_failure
  assert_output_contains "contains a parent directory reference"

  run file_backup_path "../.env"
  assert_failure

  run file_backup_path "${BATS_TEST_TMPDIR}/..hidden.env"
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/bats-helpers-backup/${BATS_TEST_TMPDIR#/}/..hidden.env"
}

@test "file_backup_path without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_TEST_TMPDIR=""
  run file_backup_path ".env"
  BATS_TEST_TMPDIR="${original}"

  assert_failure
}

@test "add_var_to_file and restore_file" {
  local backup="${BATS_TEST_TMPDIR}/bats-helpers-backup/${BATS_TEST_TMPDIR#/}/.env"

  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"
  echo "line2" >>"${BATS_TEST_TMPDIR}/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/.env" "VAR" "value"

  assert_file_exists "${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"

  assert_file_exists "${backup}"
  assert_file_contains "${backup}" "line1"
  assert_file_contains "${backup}" "line2"
  assert_file_not_contains "${backup}" "VAR=value"

  restore_file "${BATS_TEST_TMPDIR}/.env"

  assert_file_exists "${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
}

@test "add_var_to_file and restore_file in a custom directory" {
  export BATS_HELPERS_BACKUP_DIR="${BATS_TEST_TMPDIR}/custom"

  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/.env" "VAR" "value"

  assert_file_exists "${BATS_HELPERS_BACKUP_DIR}/${BATS_TEST_TMPDIR#/}/.env"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/bats-helpers-backup/${BATS_TEST_TMPDIR#/}/.env"

  restore_file "${BATS_TEST_TMPDIR}/.env"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
}

@test "add_var_to_file preserves the value verbatim" {
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/.env" "VAR" "*"

  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=*"
}

@test "add_var_to_file backs up files independently" {
  echo "first" >>"${BATS_TEST_TMPDIR}/first.env"
  echo "second" >>"${BATS_TEST_TMPDIR}/second.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/first.env" "VAR" "1"
  add_var_to_file "${BATS_TEST_TMPDIR}/second.env" "VAR" "2"

  restore_file "${BATS_TEST_TMPDIR}/first.env"

  assert_file_contains "${BATS_TEST_TMPDIR}/first.env" "first"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/first.env" "VAR=1"

  assert_file_contains "${BATS_TEST_TMPDIR}/second.env" "second"
  assert_file_contains "${BATS_TEST_TMPDIR}/second.env" "VAR=2"
}

# The file assertions glob their argument, so a path with spaces is read back
# with "cat" instead.
@test "add_var_to_file and restore_file with spaces in the path" {
  mkdir -p "${BATS_TEST_TMPDIR}/dir with spaces"
  echo "line1" >>"${BATS_TEST_TMPDIR}/dir with spaces/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/dir with spaces/.env" "VAR" "value"

  run cat "${BATS_TEST_TMPDIR}/dir with spaces/.env"
  assert_success
  assert_output_contains "VAR=value"

  restore_file "${BATS_TEST_TMPDIR}/dir with spaces/.env"

  run cat "${BATS_TEST_TMPDIR}/dir with spaces/.env"
  assert_success
  assert_output_contains "line1"
  assert_output_not_contains "VAR=value"
}

@test "add_var_to_file for a missing file" {
  run add_var_to_file "${BATS_TEST_TMPDIR}/missing.env" "VAR" "value"
  assert_failure
  assert_output_contains "does not exist"

  assert_file_not_exists "${BATS_TEST_TMPDIR}/missing.env"
}

@test "restore_file without a backup" {
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  run restore_file "${BATS_TEST_TMPDIR}/.env"
  assert_failure
  assert_output_contains "Backup for file"

  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
}
