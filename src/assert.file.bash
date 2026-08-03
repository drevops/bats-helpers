#!/usr/bin/env bash
##
# @file
# Assertions for files and directories.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2086

##
# Asserts that a file exists.
#
# Arguments:
#   1. file: Path to check. May be a glob, in which case the first match is
#      taken.
##
assert_file_exists() {
  local file="${1}"
  local f

  for f in ${file}; do
    if [ -e "${f}" ]; then
      return 0
    fi

    # Only the first match decides the outcome.
    break
  done

  format_error "File '${file}' does not exist" | flunk
}

##
# Asserts that a file does not exist.
#
# Arguments:
#   1. file: Path to check. May be a glob, in which case the first match is
#      taken.
##
assert_file_not_exists() {
  local file="${1}"
  local f

  for f in ${file}; do
    if [ -e "${f}" ]; then
      format_error "File '${file}' exists, but should not" | flunk
      return 1
    fi

    # Only the first match decides the outcome.
    break
  done

  return 0
}

##
# Asserts that a directory exists.
#
# Arguments:
#   1. dir: Path to check.
##
assert_dir_exists() {
  local dir="${1}"

  if [ -d "${dir}" ]; then
    return 0
  else
    format_error "Directory '${dir}' does not exist" | flunk
  fi
}

##
# Asserts that a directory does not exist.
#
# Arguments:
#   1. dir: Path to check. Optional, defaults to the current directory.
##
assert_dir_not_exists() {
  local dir="${1:-$(pwd)}"

  if [ -d "${dir}" ]; then
    format_error "Directory '${dir}' exists, but should not" | flunk
  else
    return 0
  fi
}

##
# Asserts that a directory exists and is empty.
#
# Arguments:
#   1. dir: Path to check. Optional, defaults to the current directory.
##
assert_dir_empty() {
  local dir="${1:-$(pwd)}"
  assert_dir_exists "${dir}" || return 1

  if [ "$(ls -A "${dir}")" ]; then
    format_error "Directory '${dir}' is not empty" | flunk
  else
    return 0
  fi
}

##
# Asserts that a directory exists and is not empty.
#
# Arguments:
#   1. dir: Path to check. Optional, defaults to the current directory.
##
assert_dir_not_empty() {
  local dir="${1:-$(pwd)}"
  assert_dir_exists "${dir}" || return 1

  if [ "$(ls -A "${dir}")" ]; then
    return 0
  else
    format_error "Directory '${dir}' is empty, but should not be" | flunk
  fi
}

##
# Asserts that a symlink exists.
#
# Arguments:
#   1. file: Path to check.
##
assert_symlink_exists() {
  local file="${1}"

  if [ ! -h "${file}" ] && [ -f "${file}" ]; then
    format_error "Regular file '${file}' exists, but should be a symlink" | flunk
  elif [ ! -h "${file}" ]; then
    format_error "Symlink '${file}' does not exist" | flunk
  else
    return 0
  fi
}

##
# Asserts that a symlink does not exist.
#
# A regular file at the same path satisfies this assertion.
#
# Arguments:
#   1. file: Path to check.
##
assert_symlink_not_exists() {
  local file="${1}"

  if [ ! -h "${file}" ]; then
    return 0
  else
    format_error "Symlink '${file}' exists, but should not" | flunk
  fi
}

##
# Asserts that a file has a permission mode.
#
# The actual mode is masked with the standard umask before comparison, so the
# group and other write bits are ignored.
#
# Arguments:
#   1. file: Path to check.
#   2. perm: Expected three-digit octal mode, such as '644'.
##
assert_file_mode() {
  local file="${1}"
  local perm="${2}"
  local parsed
  assert_file_exists "${file}" || return 1

  if [ "$(uname)" = "Darwin" ]; then
    parsed=$(printf "%.3o\n" $(($(stat -f '0%Lp' "$file") & ~0022)))
  else
    parsed=$(printf "%.3o\n" $(($(stat --printf '0%a' "$file") & ~0022)))
  fi

  if [ "${parsed}" != "${perm}" ]; then
    format_error "File '${file}' has permissions '${parsed}', but should have '${perm}'" | flunk
  else
    return 0
  fi
}

##
# Asserts on the contents of a file given as the second-to-last argument.
#
# A negated assertion passes for a file that does not exist, which cannot hold
# the needle; a positive one asserts that the file exists first.
#
# Arguments:
#   1. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   2. negate: '1' to assert that the needle does not match.
#   3. mode: Match mode option to apply before the caller's own, or an empty
#      string.
#   4. options: Match mode options. Optional, see 'string_assert_match'.
#   5. file: File to search.
#   6. string: String to search for.
##
file_assert_match() {
  local anchor="${1}"
  local negate="${2}"
  local mode="${3}"
  shift 3

  local -a args=()
  [ -n "${mode}" ] && args+=("${mode}")

  while [ "$#" -gt 2 ]; do
    args+=("${1}")
    shift
  done

  if [ "$#" -ne 2 ]; then
    flunk "A file and a string are required."
    return 1
  fi

  local file="${1}"

  if [ "${negate}" = "1" ]; then
    [ ! -f "${file}" ] && return 0
  else
    assert_file_exists "${file}" || return 1
  fi

  local contents
  contents="$(cat "${file}")"

  args+=("--" "${2}")

  string_assert_match "${anchor}" "${negate}" "${contents}" "${args[@]}"
}

##
# Asserts that a file exists and contains a string.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. file: File to search.
#   3. string: String to search for.
##
assert_file_contains() {
  file_assert_match "anywhere" 0 "" "$@"
}

##
# Asserts that a file does not contain a string.
#
# A file that does not exist cannot contain the string, so it passes.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. file: File to search.
#   3. string: String to search for.
##
assert_file_not_contains() {
  file_assert_match "anywhere" 1 "" "$@"
}

##
# Asserts that a file exists and matches an extended regular expression.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. file: File to search.
#   3. string: Extended regular expression to match.
##
assert_file_matches() {
  file_assert_match "anywhere" 0 "--regex" "$@"
}

##
# Asserts that a file does not match an extended regular expression.
#
# A file that does not exist cannot match, so it passes.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. file: File to search.
#   3. string: Extended regular expression to match.
##
assert_file_not_matches() {
  file_assert_match "anywhere" 1 "--regex" "$@"
}

##
# Builds the 'grep' parameters excluding directories from a recursive search.
#
# Globals:
#   BATS_HELPERS_ASSERT_DIR_EXCLUDE: Additional directory names to exclude from
#     the search.
#
# Outputs:
#   STDOUT: One '--exclude-dir' parameter per line, so that a directory name
#     containing spaces survives being read back into an array.
##
assert_dir_exclude_params() {
  local -a exclude_dirs=(".git" ".idea" "vendor" "node_modules")

  if [ -n "${BATS_HELPERS_ASSERT_DIR_EXCLUDE+x}" ]; then
    exclude_dirs+=("${BATS_HELPERS_ASSERT_DIR_EXCLUDE[@]}")
  elif [ -n "${ASSERT_DIR_EXCLUDE+x}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'ASSERT_DIR_EXCLUDE' will be removed in the next version. Use 'BATS_HELPERS_ASSERT_DIR_EXCLUDE' instead." >&3
    exclude_dirs+=("${ASSERT_DIR_EXCLUDE[@]}")
  fi

  local exclude_dir
  for exclude_dir in "${exclude_dirs[@]}"; do
    [ -n "${exclude_dir}" ] && printf '%s\n' "--exclude-dir=${exclude_dir}"
  done

  return 0
}

##
# Asserts that a directory exists and contains a string in one of its files.
#
# Binary files are skipped. '.git', '.idea', 'vendor' and 'node_modules' are
# always excluded from the search.
#
# Arguments:
#   1. dir: Directory to search.
#   2. string: String to search for.
#
# Globals:
#   BATS_HELPERS_ASSERT_DIR_EXCLUDE: Additional directory names to exclude from
#     the search.
##
assert_dir_contains_string() {
  local dir="${1}"
  local string="${2}"

  assert_dir_exists "${dir}" || return 1

  local -a exclude_params
  mapfile -t exclude_params < <(assert_dir_exclude_params)

  if grep -rI "${exclude_params[@]}" -l "${string}" "${dir}"; then
    return 0
  else
    format_error "Directory '${dir}' does not contain string '${string}'" | flunk
  fi
}

##
# Asserts that a directory does not contain a string in any of its files.
#
# Binary files are skipped. '.git', '.idea', 'vendor' and 'node_modules' are
# always excluded from the search. A directory that does not exist cannot
# contain the string, so it passes.
#
# Arguments:
#   1. dir: Directory to search.
#   2. string: String to search for.
#
# Globals:
#   BATS_HELPERS_ASSERT_DIR_EXCLUDE: Additional directory names to exclude from
#     the search.
##
assert_dir_not_contains_string() {
  local dir="${1}"
  local string="${2}"

  [ ! -d "${dir}" ] && return 0

  local -a exclude_params
  mapfile -t exclude_params < <(assert_dir_exclude_params)

  if grep -rI "${exclude_params[@]}" -l "${string}" "${dir}"; then
    format_error "Directory '${dir}' contains string '${string}', but should not" | flunk
  else
    return 0
  fi
}

##
# Asserts that the contents of two text files are equal.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
#   3. ignore_spaces: Set to '1' to ignore blank lines and whitespace changes.
#      Optional, defaults to '0'.
##
assert_files_equal() {
  local file1="${1}"
  local file2="${2}"
  local ignore_spaces="${3:-0}"

  local diff_opts=(--normal)
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if diff "${diff_opts[@]}" "${file1}" "${file2}"; then
    return 0
  else
    format_error "File '${file1}' is not equal to file '${file2}'" | flunk
  fi
}

##
# Asserts that the contents of two text files are not equal.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
#   3. ignore_spaces: Set to '1' to ignore blank lines and whitespace changes.
#      Optional, defaults to '0'.
##
assert_files_not_equal() {
  local file1="${1}"
  local file2="${2}"
  local ignore_spaces="${3:-0}"

  local diff_opts=(--normal)
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if diff "${diff_opts[@]}" "${file1}" "${file2}"; then
    format_error "File '${file1}' is equal to file '${file2}', but should not be" | flunk
  else
    return 0
  fi
}

##
# Asserts that the contents of two binary files are equal.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
##
assert_binary_files_equal() {
  local file1="${1}"
  local file2="${2}"

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if cmp "${file1}" "${file2}"; then
    return 0
  else
    format_error "File '${file1}' is not equal to file '${file2}'" | flunk
  fi
}

##
# Asserts that the contents of two binary files are not equal.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
##
assert_binary_files_not_equal() {
  local file1="${1}"
  local file2="${2}"

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if cmp "${file1}" "${file2}"; then
    format_error "File '${file1}' is equal to file '${file2}', but should not be" | flunk
  else
    return 0
  fi
}

##
# Asserts that two directories hold the same files with the same contents.
#
# Both directories are walked, so a file present in only one of them fails the
# assertion regardless of which one holds it.
#
# Arguments:
#   1. dir1: First directory.
#   2. dir2: Second directory.
##
assert_dirs_equal() {
  local dir1="${1}"
  local dir2="${2}"
  local file

  assert_dir_exists "${dir1}" || return 1
  assert_dir_exists "${dir2}" || return 1

  for file in $(find "${dir1}/" -type f); do
    assert_binary_files_equal "${file}" "${file/${dir1}/${dir2}}" || return 1
  done

  for file in $(find "${dir2}/" -type f); do
    assert_binary_files_equal "${file}" "${file/${dir2}/${dir1}}" || return 1
  done

  return 0
}
