#!/usr/bin/env bats
#
# Tests for the deprecated aliases.
#
# Each test asserts that the old name still works and still warns. File
# descriptor 3 is redirected per call so the notice can be asserted on.
#
# shellcheck disable=SC2030,SC2031,SC2034,SC2129

load _test_helper

@test "assert_not_git_repo" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"

  assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_not_git_repo' will be removed in v2.1. Use 'assert_git_not_repo' instead."
}

@test "assert_git_file_is_tracked" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null

  assert_git_file_is_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_git_file_is_tracked' will be removed in v2.1. Use 'assert_git_file_tracked' instead."
}

@test "assert_git_file_is_not_tracked" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/2.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null

  assert_git_file_is_not_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_git_file_is_not_tracked' will be removed in v2.1. Use 'assert_git_file_not_tracked' instead."
}

@test "assert_contains" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  assert_contains "needle" "some needle in a haystack" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_contains' will be removed in v2.1. Use 'assert_string_contains' instead."
}

@test "assert_not_contains" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  assert_not_contains "otherneedle" "some needle in a haystack" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_not_contains' will be removed in v2.1. Use 'assert_string_not_contains' instead."
}

@test "random_string" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  run random_string 5 3>"${notice}"

  assert_success
  assert_equal 5 "${#output}"
  assert_empty "${output//[a-zA-Z0-9]/}"
  assert_file_contains "${notice}" "Deprecated: 'random_string' will be removed in v2.1. Use 'string_random' instead."
}

@test "run_steps" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  declare -a STEPS=(
    "Some Substring"
  )

  run echo "Some Substring"
  run_steps "assert" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'run_steps' will be removed in v2.1. Use 'steps_run' instead."
}

@test "setup_mock" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  setup_mock 3>"${notice}"

  assert_dir_exists "${BATS_HELPERS_MOCK_TMPDIR}"
  assert_file_contains "${notice}" "Deprecated: 'setup_mock' will be removed in v2.1. Use 'mock_setup' instead."
}

@test "mktouch" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  mktouch "${BATS_TEST_TMPDIR}/dir1/dir2/file.txt" 3>"${notice}"

  assert_file_exists "${BATS_TEST_TMPDIR}/dir1/dir2/file.txt"
  assert_file_contains "${notice}" "Deprecated: 'mktouch' will be removed in v2.1. Use 'file_mktouch' instead."
}

@test "file_add_var with the deprecated backup directory variable" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export BATS_HELPERS_BACKUP_DIR="${BATS_TEST_TMPDIR}/backups"
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  file_add_var "${BATS_TEST_TMPDIR}/.env" "VAR" "value" 3>"${notice}"

  assert_file_exists "${BATS_TEST_TMPDIR}/backups/${BATS_TEST_TMPDIR#/}/.env"
  assert_file_contains "${notice}" "Deprecated: 'BATS_HELPERS_BACKUP_DIR' will be removed in v2.1. Use 'BATS_HELPERS_FILE_BACKUP_DIR' instead."
}

@test "assert_failure with the deprecated status option" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  run bash -c 'exit 2'
  assert_failure --status 2 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'assert_failure --status' will be removed in v2.1. Use 'assert_failure_status' instead."
}

@test "assert_files_equal and assert_files_not_equal with the deprecated ignore_spaces argument" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text.txt" "${BATS_TEST_TMPDIR}/text.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_newline.txt" "${BATS_TEST_TMPDIR}/text_newline.txt"
  cp "${BATS_TEST_DIRNAME}/fixtures/text_changed.txt" "${BATS_TEST_TMPDIR}/text_changed.txt"

  assert_files_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_newline.txt" 1 3>"${notice}"
  assert_files_not_equal "${BATS_TEST_TMPDIR}/text.txt" "${BATS_TEST_TMPDIR}/text_changed.txt" 1 3>>"${notice}"

  assert_file_contains "${notice}" "Deprecated: the 'ignore_spaces' argument of 'assert_files_equal' will be removed in v2.1. Use 'assert_files_equal_ignore_spaces' instead."
  assert_file_contains "${notice}" "Deprecated: the 'ignore_spaces' argument of 'assert_files_not_equal' will be removed in v2.1. Use 'assert_files_not_equal_ignore_spaces' instead."
}

@test "trim_file" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  echo "line1" >>"${BATS_TEST_TMPDIR}/file.txt"
  echo "line2" >>"${BATS_TEST_TMPDIR}/file.txt"

  trim_file "${BATS_TEST_TMPDIR}/file.txt" 3>"${notice}"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/file.txt" "line2"
  assert_file_contains "${notice}" "Deprecated: 'trim_file' will be removed in v2.1. Use 'file_trim' instead."
}

@test "read_env" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  pushd "${BATS_TEST_TMPDIR}"
  echo "VAR1=val1" >>.env

  # shellcheck disable=SC2016
  run read_env '$VAR1' 3>"${notice}"

  assert_success
  assert_output_contains "val1"
  assert_file_contains "${notice}" "Deprecated: 'read_env' will be removed in v2.1. Use 'file_read_env' instead."

  popd
}

@test "add_var_to_file and restore_file" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  echo "line1" >>"${BATS_TEST_TMPDIR}/.env"

  add_var_to_file "${BATS_TEST_TMPDIR}/.env" "VAR" "value" 3>"${notice}"

  assert_file_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
  assert_file_contains "${notice}" "Deprecated: 'add_var_to_file' will be removed in v2.1. Use 'file_add_var' instead."

  restore_file "${BATS_TEST_TMPDIR}/.env" 3>>"${notice}"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/.env" "VAR=value"
  assert_file_contains "${notice}" "Deprecated: 'restore_file' will be removed in v2.1. Use 'file_restore' instead."
}

@test "tui_run with the deprecated nothing answer" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  tui_run "nothing" "custom answer2" 3>"${notice}"

  assert_output_contains "default answer1"
  assert_file_contains "${notice}" "Deprecated: the 'nothing' answer will be removed in v2.1. Use an empty string instead."
}

@test "steps_run with the deprecated debug variable" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export RUN_STEPS_DEBUG=1

  run echo "Some Substring"
  declare -a STEPS=(
    "Some Substring"
  )
  steps_run "assert" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'RUN_STEPS_DEBUG' will be removed in v2.1. Use 'BATS_HELPERS_STEPS_DEBUG' instead."
  assert_file_contains "${notice}" "  > Total steps : 1"
}

@test "assert_dir_not_contains_string with the deprecated exclude list" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/scripts/vendor2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor2/1.txt"
  declare -a ASSERT_DIR_EXCLUDE=(vendor2)

  assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing" 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'ASSERT_DIR_EXCLUDE' will be removed in v2.1. Use 'BATS_HELPERS_ASSERT_DIR_EXCLUDE' instead."
}

@test "_mock_prepare_tmp with the deprecated temporary directory variable" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  BATS_HELPERS_MOCK_TMPDIR=""
  export BATS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/custom"

  run _mock_prepare_tmp 3>"${notice}"

  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/bats-helpers-mock"
  assert_file_contains "${notice}" "Deprecated: 'BATS_MOCK_TMPDIR' will be removed in v2.1. Use 'BATS_HELPERS_MOCK_TMPDIR' instead."
}

@test "mock_get_call_user with the deprecated user variable" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export _USER="someoneelse"

  mock_curl="$(mock_command "curl" 3>"${notice}")"
  curl example.com

  assert_equal "someoneelse" "$(mock_get_call_user "${mock_curl}")"
  assert_file_contains "${notice}" "Deprecated: '_USER' will be removed in v2.1. Use 'BATS_HELPERS_MOCK_USER' instead."
}

@test "fixture_export_codebase with the deprecated enable variable" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/build"

  fixture_export_codebase "${BATS_TEST_TMPDIR}/build" 3>"${notice}"

  assert_file_exists "${BATS_TEST_TMPDIR}/build/README.md"
  assert_file_contains "${notice}" "Deprecated: 'BATS_FIXTURE_EXPORT_CODEBASE_ENABLED' will be removed in v2.1. Use 'BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED' instead."
}

@test "Prefixed variables take precedence and emit no notices" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  export RUN_STEPS_DEBUG=1
  export BATS_HELPERS_STEPS_DEBUG=0
  run echo "Some Substring"
  declare -a STEPS=("Some Substring")
  steps_run "assert" 3>"${notice}"

  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/scripts/vendor2"
  echo "some existing text" >"${BATS_TEST_TMPDIR}/fixture/scripts/vendor2/1.txt"
  declare -a ASSERT_DIR_EXCLUDE=(other)
  declare -a BATS_HELPERS_ASSERT_DIR_EXCLUDE=(vendor2)
  assert_dir_not_contains_string "${BATS_TEST_TMPDIR}/fixture" "existing" 3>>"${notice}"

  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
  export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=0
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/build"
  fixture_export_codebase "${BATS_TEST_TMPDIR}/build" 3>>"${notice}"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/build/README.md"

  export BATS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/deprecated"
  export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/prefixed"
  export _USER="deprecateduser"
  export BATS_HELPERS_MOCK_USER="prefixeduser"
  mkdir -p "${BATS_HELPERS_MOCK_TMPDIR}"
  mock_curl="$(mock_command "curl" 3>>"${notice}")"
  PATH="${BATS_HELPERS_MOCK_TMPDIR}:${PATH}" curl example.com
  assert_equal "${BATS_TEST_TMPDIR}/prefixed" "$(dirname "${mock_curl}")"
  assert_equal "prefixeduser" "$(mock_get_call_user "${mock_curl}")"

  assert_file_exists "${notice}"
  assert_empty "$(cat "${notice}")"
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

@test "Notices are silenced by the quiet variable" {
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
