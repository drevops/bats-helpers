#!/usr/bin/env bash
##
# @file
# Assertions for git repositories.
#

##
# Asserts that a directory is a git repository.
#
# Arguments:
#   1. dir: Directory to check. Optional, defaults to the current directory.
##
assert_git_repo() {
  local dir="${1:-$(pwd)}"

  assert_dir_exists "${dir}" || return 1

  if [ -d "${dir}/.git" ]; then
    local message
    message=$(git --work-tree="${dir}" --git-dir="${dir}/.git" status 2>&1)

    if echo "${message}" | $(type -p grep | head -1) -i -F -- "not a git repository" >/dev/null; then
      format_error "Directory '${dir}' is not a git repository" | flunk
      return 1
    fi

    return 0
  else
    format_error "Directory '${dir}' is not a git repository" | flunk
    return 1
  fi
}

##
# Asserts that a directory is not a git repository.
#
# Arguments:
#   1. dir: Directory to check. Optional, defaults to the current directory.
##
assert_git_not_repo() {
  local dir="${1:-$(pwd)}"

  assert_dir_exists "${dir}" || return 1

  if [ -d "${dir}/.git" ]; then
    format_error "Directory '${dir}' is a git repository, but should not be" | flunk
  else
    return 0
  fi
}

##
# Asserts that a file is tracked in a git repository.
#
# Arguments:
#   1. file: File to check.
#   2. dir: Repository directory. Optional, defaults to the current directory.
#
# Returns:
#   0 if the file is tracked, 1 otherwise. Unlike the other assertions in this
#   library, this one reports the outcome through the exit status alone and
#   prints no message.
##
assert_git_file_tracked() {
  local file="${1-}"
  local dir="${2:-$(pwd)}"

  if [ ! -d "${dir}/.git" ]; then
    return 1
  fi

  git --work-tree="${dir}" --git-dir="${dir}/.git" ls-files --error-unmatch "${file}" &>/dev/null
  return $?
}

##
# Asserts that a file is not tracked in a git repository.
#
# Arguments:
#   1. file: File to check.
#   2. dir: Repository directory. Optional, defaults to the current directory.
#
# Returns:
#   0 if the file is not tracked, 1 otherwise. Unlike the other assertions in
#   this library, this one reports the outcome through the exit status alone and
#   prints no message.
##
assert_git_file_not_tracked() {
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

##
# Asserts that a git repository has no uncommitted changes.
#
# Arguments:
#   1. dir: Repository directory. Optional, defaults to the current directory.
##
assert_git_clean() {
  local dir="${1:-$(pwd)}"
  local message

  assert_git_repo "${dir}" || return 1

  message="$(git --work-tree="${dir}" --git-dir="${dir}/.git" status)"
  assert_string_contains "${message}" "nothing to commit"
}

##
# Asserts that a git repository has uncommitted changes.
#
# Arguments:
#   1. dir: Repository directory. Optional, defaults to the current directory.
##
assert_git_not_clean() {
  local dir="${1:-$(pwd)}"
  local message

  assert_git_repo "${dir}" || return 1

  message="$(git --work-tree="${dir}" --git-dir="${dir}/.git" status)"
  assert_string_not_contains "${message}" "nothing to commit"
}

##
## Deprecated aliases, removed in the next version.
##

assert_not_git_repo() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_not_git_repo' will be removed in the next version. Use 'assert_git_not_repo' instead." >&3
  assert_git_not_repo "$@"
}

assert_git_file_is_tracked() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_git_file_is_tracked' will be removed in the next version. Use 'assert_git_file_tracked' instead." >&3
  assert_git_file_tracked "$@"
}

assert_git_file_is_not_tracked() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_git_file_is_not_tracked' will be removed in the next version. Use 'assert_git_file_not_tracked' instead." >&3
  assert_git_file_not_tracked "$@"
}
