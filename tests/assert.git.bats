#!/usr/bin/env bats
#
# Tests for git assertions.
#
# shellcheck disable=SC2129,SC2030,SC2031

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

  # Repository discovery from this directory resolves to 'git_repo'.
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/git_repo/nested_empty_dot_git"
  mkdir "${BATS_TEST_TMPDIR}/fixture/git_repo/nested_empty_dot_git/.git"
  run assert_git_repo "${BATS_TEST_TMPDIR}/fixture/git_repo/nested_empty_dot_git"
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

  # Git exports 'GIT_DIR' to hooks, so a suite run from one inherits it.
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/dirty_repo"
  git --work-tree="${BATS_TEST_TMPDIR}/fixture/dirty_repo" --git-dir="${BATS_TEST_TMPDIR}/fixture/dirty_repo/.git" init >/dev/null
  file_mktouch "${BATS_TEST_TMPDIR}/fixture/dirty_repo/uncommitted_file"
  GIT_DIR="${BATS_TEST_TMPDIR}/fixture/dirty_repo/.git" assert_git_clean "${BATS_TEST_TMPDIR}/fixture/git_repo"

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

##
## Repository-discovery isolation (#218): an assertion addresses the exact
## directory it is given. An inherited `GIT_DIR` or an enclosing repository
## must never answer in its place.
##
## Fixture setup runs from inside the directory being built (with GIT_DIR
## cleared) so these tests are independent of how git resolves paths on the
## platform running them; the assertions under test always use the explicit
## --git-dir/--work-tree form.
##

@test "assert_git_repo fails on a directory with no .git even when GIT_DIR names a repository" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/other_repo"
  (cd "${BATS_TEST_TMPDIR}/fixture/other_repo" && env -u GIT_DIR git init >/dev/null)

  export GIT_DIR="${BATS_TEST_TMPDIR}/fixture/other_repo/.git"
  run assert_git_repo "${BATS_TEST_TMPDIR}/fixture/not_git_repo"
  unset GIT_DIR

  assert_failure
}

@test "assert_git_repo fails on an inner directory with an empty .git, not on the enclosing repository" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/parent_repo"
  (
    cd "${BATS_TEST_TMPDIR}/fixture/parent_repo" || exit 1
    env -u GIT_DIR git init >/dev/null
    echo seed >1.txt
    env -u GIT_DIR git add 1.txt
    env -u GIT_DIR git commit -m "seed" >/dev/null
  )
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/parent_repo/inner/.git"

  # Discovery from the inner directory resolves to the clean parent and
  # reports it as a repository; only the explicit git dir reports the truth.
  run assert_git_repo "${BATS_TEST_TMPDIR}/fixture/parent_repo/inner"
  assert_failure
}

@test "assert_git_clean fails on an inner directory with an empty .git, not on the enclosing repository" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/parent_repo"
  (
    cd "${BATS_TEST_TMPDIR}/fixture/parent_repo" || exit 1
    env -u GIT_DIR git init >/dev/null
    echo seed >1.txt
    env -u GIT_DIR git add 1.txt
    env -u GIT_DIR git commit -m "seed" >/dev/null
  )
  mkdir -p "${BATS_TEST_TMPDIR}/fixture/parent_repo/inner/.git"

  # The parent is clean, so discovery would pass; the inner directory is not
  # a repository at all, so the assertion must fail.
  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/parent_repo/inner"
  assert_failure
}

@test "assert_git_clean judges the directory it is given, not GIT_DIR's repository" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/clean_repo"
  (
    cd "${BATS_TEST_TMPDIR}/fixture/clean_repo" || exit 1
    env -u GIT_DIR git init >/dev/null
    echo seed >1.txt
    env -u GIT_DIR git add 1.txt
    env -u GIT_DIR git commit -m "seed" >/dev/null
  )
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/dirty_repo"
  (
    cd "${BATS_TEST_TMPDIR}/fixture/dirty_repo" || exit 1
    env -u GIT_DIR git init >/dev/null
    echo seed >1.txt
    env -u GIT_DIR git add 1.txt
    env -u GIT_DIR git commit -m "seed" >/dev/null
    echo dirty >>1.txt
  )

  export GIT_DIR="${BATS_TEST_TMPDIR}/fixture/clean_repo/.git"
  run assert_git_clean "${BATS_TEST_TMPDIR}/fixture/dirty_repo"
  unset GIT_DIR

  assert_failure
}

@test "assert_git_file_tracked judges the directory it is given, not GIT_DIR's repository" {
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/tracked_repo"
  (
    cd "${BATS_TEST_TMPDIR}/fixture/tracked_repo" || exit 1
    env -u GIT_DIR git init >/dev/null
    echo seed >1.txt
    env -u GIT_DIR git add 1.txt
    env -u GIT_DIR git commit -m "seed" >/dev/null
  )
  fixture_prepare_dir "${BATS_TEST_TMPDIR}/fixture/empty_repo"
  (
    cd "${BATS_TEST_TMPDIR}/fixture/empty_repo" || exit 1
    env -u GIT_DIR git init >/dev/null
  )

  export GIT_DIR="${BATS_TEST_TMPDIR}/fixture/tracked_repo/.git"
  run assert_git_file_tracked "1.txt" "${BATS_TEST_TMPDIR}/fixture/empty_repo"
  unset GIT_DIR

  assert_failure
}
