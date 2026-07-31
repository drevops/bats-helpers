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

@test "Assertions calling other assertions emit no notices" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  echo "some needle in a haystack" >"${BATS_TEST_TMPDIR}/haystack.txt"

  assert_file_contains "${BATS_TEST_TMPDIR}/haystack.txt" "needle" 3>"${notice}"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/haystack.txt" "otherneedle" 3>>"${notice}"
  assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo" 3>>"${notice}"
  mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/uncommitted_file"
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
