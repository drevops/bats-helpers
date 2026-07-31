#!/usr/bin/env bats
#
# Tests for the deprecated aliases.
#
# Each test asserts that the old name still works and still warns. File
# descriptor 3 is redirected per call so the notice can be asserted on.
#
# shellcheck disable=SC2129

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

@test "setup_mock" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  setup_mock 3>"${notice}"

  assert_file_contains "${notice}" "Deprecated: 'setup_mock' will be removed in the next version. Use 'mock_setup' instead."
}

@test "Notices are silenced" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  export BATS_HELPERS_DEPRECATION_QUIET=1

  setup_mock 3>"${notice}"

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
