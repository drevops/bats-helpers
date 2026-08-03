#!/usr/bin/env bats
#
# Tests for file utilities.
#
# shellcheck disable=SC2129,SC2030,SC2031

load _test_helper

@test "file_mktouch" {
  assert_file_not_exists "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
  file_mktouch "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
  assert_file_exists "${BATS_TEST_TMPDIR}/dir1/dir2/dir3/file.txt"
}

@test "file_trim" {
  echo "line1" >>"${BATS_TEST_TMPDIR}/file.txt"
  echo "line2" >>"${BATS_TEST_TMPDIR}/file.txt"
  echo "line3" >>"${BATS_TEST_TMPDIR}/file.txt"

  file_trim "${BATS_TEST_TMPDIR}/file.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/file.txt" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/file.txt" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line3"

  file_trim "${BATS_TEST_TMPDIR}/file.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/file.txt" "line1"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line3"
}

@test "file_read_env" {
  pushd "${BATS_TEST_TMPDIR}"

  assert_file_not_exists ".env"

  echo "VAR1=val1" >>.env
  echo "VAR2=val2" >>.env
  # shellcheck disable=SC2016
  run file_read_env '$VAR1'
  assert_output_contains "val1"
  # shellcheck disable=SC2016
  run file_read_env '$VAR2'
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

@test "file_add_var and file_restore" {
  local backup="${BATS_TEST_TMPDIR}/bats-helpers-backup/${BATS_TEST_TMPDIR#/}/.env"

  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"
  echo "line2" >>"${BATS_TEST_TMPDIR}/.env"

  file_add_var "${BATS_TEST_TMPDIR}/.env" "VAR" "value"

  assert_file_exists "${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"

  assert_file_exists "${backup}"
  assert_file_contains "${backup}" "line1"
  assert_file_contains "${backup}" "line2"
  assert_file_not_contains "${backup}" "VAR=value"

  file_restore "${BATS_TEST_TMPDIR}/.env"

  assert_file_exists "${BATS_TEST_TMPDIR}/.env"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line2"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
}

@test "file_add_var and file_restore in a custom directory" {
  export BATS_HELPERS_BACKUP_DIR="${BATS_TEST_TMPDIR}/custom"

  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  file_add_var "${BATS_TEST_TMPDIR}/.env" "VAR" "value"

  assert_file_exists "${BATS_HELPERS_BACKUP_DIR}/${BATS_TEST_TMPDIR#/}/.env"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/bats-helpers-backup/${BATS_TEST_TMPDIR#/}/.env"

  file_restore "${BATS_TEST_TMPDIR}/.env"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
}

@test "file_add_var preserves the value verbatim" {
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  file_add_var "${BATS_TEST_TMPDIR}/.env" "VAR" "*"

  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=*"
}

@test "file_add_var backs up files independently" {
  echo "first" >>"${BATS_TEST_TMPDIR}/first.env"
  echo "second" >>"${BATS_TEST_TMPDIR}/second.env"

  file_add_var "${BATS_TEST_TMPDIR}/first.env" "VAR" "1"
  file_add_var "${BATS_TEST_TMPDIR}/second.env" "VAR" "2"

  file_restore "${BATS_TEST_TMPDIR}/first.env"

  assert_file_contains "${BATS_TEST_TMPDIR}/first.env" "first"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/first.env" "VAR=1"

  assert_file_contains "${BATS_TEST_TMPDIR}/second.env" "second"
  assert_file_contains "${BATS_TEST_TMPDIR}/second.env" "VAR=2"
}

# The file assertions glob their argument, so a path with spaces is read back
# with "cat" instead.
@test "file_add_var and file_restore with spaces in the path" {
  mkdir -p "${BATS_TEST_TMPDIR}/dir with spaces"
  echo "line1" >>"${BATS_TEST_TMPDIR}/dir with spaces/.env"

  file_add_var "${BATS_TEST_TMPDIR}/dir with spaces/.env" "VAR" "value"

  run cat "${BATS_TEST_TMPDIR}/dir with spaces/.env"
  assert_success
  assert_output_contains "VAR=value"

  file_restore "${BATS_TEST_TMPDIR}/dir with spaces/.env"

  run cat "${BATS_TEST_TMPDIR}/dir with spaces/.env"
  assert_success
  assert_output_contains "line1"
  assert_output_not_contains "VAR=value"
}

@test "file_add_var for a missing file" {
  run file_add_var "${BATS_TEST_TMPDIR}/missing.env" "VAR" "value"
  assert_failure
  assert_output_contains "does not exist"

  assert_file_not_exists "${BATS_TEST_TMPDIR}/missing.env"
}

@test "file_restore without a backup" {
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  run file_restore "${BATS_TEST_TMPDIR}/.env"
  assert_failure
  assert_output_contains "Backup for file"

  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "line1"
}
