#!/usr/bin/env bats
#
# Tests for the deprecated aliases.
#
# Each test asserts that the old name still works and still warns. File
# descriptor 3 is redirected per call so the notice can be asserted on.
#
# shellcheck disable=SC2034,SC2129

load _test_helper

@test "assert_not_git_repo" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"

  assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_not_git_repo' will be removed in the next version. Use 'assert_git_not_repo' instead."
}

@test "assert_git_file_is_tracked" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null

  assert_git_file_is_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_git_file_is_tracked' will be removed in the next version. Use 'assert_git_file_tracked' instead."
}

@test "assert_git_file_is_not_tracked" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/2.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null

  assert_git_file_is_not_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_git_file_is_not_tracked' will be removed in the next version. Use 'assert_git_file_not_tracked' instead."
}

@test "assert_contains" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  assert_contains "needle" "some needle in a haystack" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_contains' will be removed in the next version. Use 'assert_string_contains' instead."
}

@test "assert_not_contains" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  assert_not_contains "otherneedle" "some needle in a haystack" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_not_contains' will be removed in the next version. Use 'assert_string_not_contains' instead."
}

@test "random_string" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  run random_string 5 3>"${notice}"

  assert_success
  assert_equal 5 "${#output}"
  assert_string_not_contains "${output}" " "
  assert_file_contains "${notice}" "Deprecated: 'random_string' will be removed in the next version. Use 'string_random' instead."
}

@test "run_steps" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  declare -a STEPS=(
    "Some Substring"
  )

  run echo "Some Substring"
  run_steps "assert" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'run_steps' will be removed in the next version. Use 'steps_run' instead."
}

@test "setup_mock" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  setup_mock 3>"${notice}"

  assert_dir_exists "${BATS_MOCK_TMPDIR}"
  assert_file_contains "${notice}" "Deprecated: 'setup_mock' will be removed in the next version. Use 'mock_setup' instead."
}

@test "mktouch" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  mktouch "${BATS_TEST_TMPDIR}/dir1/dir2/file.txt" 3>"${notice}"

  assert_file_exists "${BATS_TEST_TMPDIR}/dir1/dir2/file.txt"
  assert_file_contains "${notice}" "Deprecated: 'mktouch' will be removed in the next version. Use 'file_mktouch' instead."
}

@test "trim_file" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  echo "line1" >>"${BATS_TEST_TMPDIR}/file.txt"
  echo "line2" >>"${BATS_TEST_TMPDIR}/file.txt"

  trim_file "${BATS_TEST_TMPDIR}/file.txt" 3>"${notice}"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line2"
  assert_file_contains "${notice}" "Deprecated: 'trim_file' will be removed in the next version. Use 'file_trim' instead."
}

@test "read_env" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  pushd "${BATS_TEST_TMPDIR}"
  echo "VAR1=val1" >>.env

  # shellcheck disable=SC2016
  run read_env '$VAR1' 3>"${notice}"

  assert_output_contains "val1"
  assert_file_contains "${notice}" "Deprecated: 'read_env' will be removed in the next version. Use 'file_read_env' instead."

  popd
}

@test "add_var_to_file and restore_file" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/.env" "VAR" "value" 3>"${notice}"

  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
  assert_file_contains "${notice}" "Deprecated: 'add_var_to_file' will be removed in the next version. Use 'file_add_var' instead."

  restore_file "${BATS_TEST_TMPDIR}/.env" 3>>"${notice}"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
  assert_file_contains "${notice}" "Deprecated: 'restore_file' will be removed in the next version. Use 'file_restore' instead."
}

@test "Assertions calling other assertions emit no notices" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  echo "some needle in a haystack" >"${BATS_TEST_TMPDIR}/haystack.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/haystack.txt" "needle" 3>"${notice}"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/haystack.txt" "otherneedle" 3>>"${notice}"
  assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>>"${notice}"
  file_mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/uncommitted_file"
  assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>>"${notice}"

  run echo "some needle in a haystack"
  assert_output_contains "needle" 3>>"${notice}"
  assert_output_not_contains "otherneedle" 3>>"${notice}"

  assert_file_exists "${notice}"
  assert_empty "$(cat "${notice}")"
}

@test "Notices are silenced" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export BATS_HELPERS_DEPRECATION_QUIET=1
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"

  assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo" 3>"${notice}"

  assert_file_exists "${notice}"
  assert_empty "$(cat "${notice}")"
}

@test "Notices are repeated on every call" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"

  assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo" 3>"${notice}"
  assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo" 3>>"${notice}"

  assert_equal "2" "$(grep -c "assert_not_git_repo" "${notice}")"
}
