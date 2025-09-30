#!/usr/bin/env bash
##
# @file
# Assertions for git repositories.
#

assert_git_repo() {
  local dir="${1:-$(pwd)}"

  assert_dir_exists "${dir}" || return 1

  if [ -d "${dir}/.git" ]; then
    log=$(git --work-tree="${dir}" --git-dir="${dir}/.git" status 2>&1)

    if echo "${log}" | $(type -p grep | head -1) -i -F -- "not a git repository" >/dev/null; then
      format_error "Directory ${dir} exists, but it is not a git repository" | flunk
      return 1
    fi

    return 0
  else
    format_error "Directory ${dir} exists, but it is not a git repository" | flunk
    return 1
  fi
}

assert_not_git_repo() {
  local dir="${1:-$(pwd)}"

  assert_dir_exists "${dir}" || return 1

  if [ -d "${dir}/.git" ]; then
    format_error "Directory ${dir} exists and it is a git repository, but should not be" | flunk
  else
    return 0
  fi
}

assert_git_file_is_tracked() {
  local file="${1-}"
  local dir="${2:-$(pwd)}"

  if [ ! -d "${dir}/.git" ]; then
    return 1
  fi

  git --work-tree="${dir}" --git-dir="${dir}/.git" ls-files --error-unmatch "${file}" &>/dev/null
  return $?
}

assert_git_file_is_not_tracked() {
  local file="${1-}"
  local dir="${2:-$(pwd)}"

  if [ ! -d "${dir}/.git" ]; then
    return 1
  fi

  if git --work-tree="${dir}" --git-dir="${dir}/.git" ls-files --error-unmatch "${file}" &>/dev/null; then
    return 1
  else
    return 0
  fi
}

assert_git_clean() {
  local dir="${1:-$(pwd)}"
  local message

  assert_git_repo "${dir}"

  message="$(git --work-tree="${dir}" --git-dir="${dir}/.git" status)"
  assert_contains "nothing to commit" "${message}"
}

assert_git_not_clean() {
  local dir="${1:-$(pwd)}"
  local message

  assert_git_repo "${dir}"

  message="$(git --work-tree="${dir}" --git-dir="${dir}/.git" status)"
  assert_not_contains "nothing to commit" "${message}"
}
