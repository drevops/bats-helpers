#!/usr/bin/env bats
#
# Tests for Bats helpers.
#
# Each assertion tests positive and negative behaviour.
#
# shellcheck disable=SC2129

load _test_helper

@test "assert_git_repo" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo_empty_dot_git"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null

  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"

  mkdir "${BATS_TEST_TMPDIR}/fixture/git_repo_empty_dot_git/.git"
  assert_dir_exists "${BATS_TEST_TMPDIR}/fixture/git_repo_empty_dot_git/.git"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/fixture/git_repo_empty_dot_git/HEAD"
  run assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo_empty_dot_git"
  assert_failure

  run assert_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure

  run assert_git_repo "${BATS_TEST_TMPDIR}/fixture/some_dir"
  assert_failure
}

@test "assert_not_git_repo" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null

  assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo"

  run assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  run assert_not_git_repo "${BATS_TEST_TMPDIR}/fixture/some_dir"
  assert_failure
}

@test "assert_git_clean" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"

  assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"

  mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/uncommitted_file"
  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  # Now, commit first file and create another, but do not add.
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add -A >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "First commit" >/dev/null
  assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/other_uncommitted_file"
  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure
}

@test "assert_git_not_clean" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/uncommitted_file"
  assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"

  # Now, commit first file and create another, but do not add.
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add -A >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "First commit" >/dev/null
  run assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure
  mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/other_uncommitted_file"
  assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
}

@test "assert_git_file_is_tracked" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/2.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "some message" >/dev/null

  assert_git_file_is_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_file_is_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  run assert_git_file_is_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure
}

@test "assert_git_file_is_not_tracked" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/2.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "some message" >/dev/null

  assert_git_file_is_not_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_file_is_not_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  run assert_git_file_is_not_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure
}
