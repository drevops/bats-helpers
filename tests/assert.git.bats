#!/usr/bin/env bats
#
# Tests for git assertions.
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

@test "assert_git_not_repo" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null

  assert_git_not_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo"

  run assert_git_not_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  run assert_git_not_repo "${BATS_TEST_TMPDIR}/fixture/some_dir"
  assert_failure
}

@test "assert_git_clean" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"

  assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure
  assert_output_contains "not a git repository"
  assert_output_not_contains "nothing to commit"

  file_mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/uncommitted_file"
  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure
  assert_output_contains "-- Repository has uncommitted changes --"
  assert_output_contains "directory"

  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add -A >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "First commit" >/dev/null
  assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  file_mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/other_uncommitted_file"
  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure
}

@test "assert_git_not_clean" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure
  assert_output_contains "not a git repository"

  run assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure
  assert_output_contains "-- Repository has no uncommitted changes, but should have --"
  assert_output_contains "directory"

  file_mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/uncommitted_file"
  assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"

  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add -A >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "First commit" >/dev/null
  run assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure
  file_mktouch "${BATS_TEST_TMPDIR}/fixture/git_repo/other_uncommitted_file"
  assert_git_not_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"
}

@test "assert_git_file_tracked" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/2.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "some message" >/dev/null

  assert_git_file_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_file_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  run assert_git_file_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure
}

@test "assert_git_file_not_tracked" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" init >/dev/null
  assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/1.txt"
  touch "${BATS_TEST_TMPDIR}/fixture/git_repo/2.txt"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" add 1.txt >/dev/null
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/git_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/git_repo/.git" commit -m "some message" >/dev/null

  assert_git_file_not_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"

  run assert_git_file_not_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/git_repo"
  assert_failure

  run assert_git_file_not_tracked "2.txt" "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  assert_failure
}
