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

  # The literal path is tried first, because the glob expansion below is
  # unquoted and would word-split a path that contains a space.
  [ -e "${file}" ] && return 0

  for f in ${file}; do
    if [ -e "${f}" ]; then
      return 0
    fi

    # Only the first match decides the outcome.
    break
  done

  format_error "File does not exist" "file" "${file}" | flunk
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

  # The literal path is tried first, because the glob expansion below is
  # unquoted and would word-split a path that contains a space.
  if [ -e "${file}" ]; then
    format_error "File exists, but should not" "file" "${file}" | flunk
    return 1
  fi

  for f in ${file}; do
    if [ -e "${f}" ]; then
      format_error "File exists, but should not" "file" "${file}" | flunk
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
#   1. dir: Path to check. Optional, defaults to the current directory.
##
assert_dir_exists() {
  local dir="${1:-$(pwd)}"

  if [ -d "${dir}" ]; then
    return 0
  else
    format_error "Directory does not exist" "directory" "${dir}" | flunk
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
    format_error "Directory exists, but should not" "directory" "${dir}" | flunk
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

  if [ -n "$(ls -A "${dir}")" ]; then
    format_error "Directory is not empty" "directory" "${dir}" | flunk
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

  if [ -n "$(ls -A "${dir}")" ]; then
    return 0
  else
    format_error "Directory is empty, but should not be" "directory" "${dir}" | flunk
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
    format_error "Regular file exists, but should be a symlink" "file" "${file}" | flunk
  elif [ ! -h "${file}" ]; then
    format_error "Symlink does not exist" "file" "${file}" | flunk
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
    format_error "Symlink exists, but should not" "file" "${file}" | flunk
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
    parsed="$(printf "%.3o\n" $(($(stat -f '0%Lp' "${file}") & ~0022)))"
  else
    parsed="$(printf "%.3o\n" $(($(stat --printf '0%a' "${file}") & ~0022)))"
  fi

  if [ "${parsed}" != "${perm}" ]; then
    format_error "File does not have the expected permissions" "file" "${file}" "expected" "${perm}" "actual" "${parsed}" | flunk
  else
    return 0
  fi
}

##
# Asserts that a needle matches the contents of a file.
#
# A negated assertion passes for a file that does not exist, which cannot hold
# the needle; a positive one asserts that the file exists first. Only a regular
# file has contents to read, so a directory or a glob is rejected rather than
# handed to 'cat'.
#
# Arguments:
#   1. subject: What the haystack is reported as - 'file'.
#   2. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   3. negate: '1' to assert that the needle does not match.
#   4. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   5. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   6. file: File to search.
#   7. string: String to search for.
##
file_assert_match() {
  if [ "$#" -ne 7 ]; then
    flunk "A file and a string are required."
    return 1
  fi

  local negate="${3}"
  local file="${6}"

  if [ "${negate}" = "1" ]; then
    [ ! -f "${file}" ] && return 0
  else
    assert_file_exists "${file}" || return 1

    if [ ! -f "${file}" ]; then
      format_error "File is not a regular file" "file" "${file}" | flunk
      return 1
    fi
  fi

  local contents
  contents="$(cat "${file}")"

  string_assert_match "${1}" "${2}" "${3}" "${4}" "${5}" "${contents}" "${7}" "${file}"
}

##
# Asserts that a file exists and contains a string, ignoring case.
#
# Arguments:
#   1. file: File to search.
#   2. string: String to search for.
##
assert_file_contains() {
  file_assert_match "file" "anywhere" 0 "literal" 0 "$@"
}

##
# Asserts that a file exists and contains a string, case-sensitively.
#
# Arguments:
#   1. file: File to search.
#   2. string: String to search for.
##
assert_file_contains_case() {
  file_assert_match "file" "anywhere" 0 "literal" 1 "$@"
}

##
# Asserts that a file does not contain a string, ignoring case.
#
# A file that does not exist cannot contain the string, so it passes.
#
# Arguments:
#   1. file: File to search.
#   2. string: String to search for.
##
assert_file_not_contains() {
  file_assert_match "file" "anywhere" 1 "literal" 0 "$@"
}

##
# Asserts that a file does not contain a string, case-sensitively.
#
# A file that does not exist cannot contain the string, so it passes.
#
# Arguments:
#   1. file: File to search.
#   2. string: String to search for.
##
assert_file_not_contains_case() {
  file_assert_match "file" "anywhere" 1 "literal" 1 "$@"
}

##
# Asserts that a file exists and matches a regular expression, ignoring case.
#
# Arguments:
#   1. file: File to search.
#   2. string: Extended regular expression to match.
##
assert_file_matches() {
  file_assert_match "file" "anywhere" 0 "regex" 0 "$@"
}

##
# Asserts that a file exists and matches a regular expression, case-sensitively.
#
# Arguments:
#   1. file: File to search.
#   2. string: Extended regular expression to match.
##
assert_file_matches_case() {
  file_assert_match "file" "anywhere" 0 "regex" 1 "$@"
}

##
# Asserts that a file does not match a regular expression, ignoring case.
#
# A file that does not exist cannot match, so it passes.
#
# Arguments:
#   1. file: File to search.
#   2. string: Extended regular expression to match.
##
assert_file_not_matches() {
  file_assert_match "file" "anywhere" 1 "regex" 0 "$@"
}

##
# Asserts that a file does not match a regular expression, case-sensitively.
#
# A file that does not exist cannot match, so it passes.
#
# Arguments:
#   1. file: File to search.
#   2. string: Extended regular expression to match.
##
assert_file_not_matches_case() {
  file_assert_match "file" "anywhere" 1 "regex" 1 "$@"
}

##
# Asserts that a file exists and matches a format string, ignoring case.
#
# Arguments:
#   1. file: File to search.
#   2. string: Format string, see 'string_format_to_regex'.
##
assert_file_matches_format() {
  file_assert_match "file" "anywhere" 0 "format" 0 "$@"
}

##
# Asserts that a file exists and matches a format string, case-sensitively.
#
# Arguments:
#   1. file: File to search.
#   2. string: Format string, see 'string_format_to_regex'.
##
assert_file_matches_format_case() {
  file_assert_match "file" "anywhere" 0 "format" 1 "$@"
}

##
# Asserts that a file does not match a format string, ignoring case.
#
# A file that does not exist cannot match, so it passes.
#
# Arguments:
#   1. file: File to search.
#   2. string: Format string, see 'string_format_to_regex'.
##
assert_file_not_matches_format() {
  file_assert_match "file" "anywhere" 1 "format" 0 "$@"
}

##
# Asserts that a file does not match a format string, case-sensitively.
#
# A file that does not exist cannot match, so it passes.
#
# Arguments:
#   1. file: File to search.
#   2. string: Format string, see 'string_format_to_regex'.
##
assert_file_not_matches_format_case() {
  file_assert_match "file" "anywhere" 1 "format" 1 "$@"
}

##
# Builds the 'grep' parameters excluding directories from a recursive search.
#
# Globals:
#   BATS_HELPERS_ASSERT_DIR_EXCLUDE: Additional directory names to exclude from
#     the search.
#   ASSERT_DIR_EXCLUDE: Deprecated name of the above.
#   BATS_HELPERS_DEPRECATION_QUIET: Non-empty suppresses this library's
#     deprecation notices.
#
# Outputs:
#   STDOUT: One '--exclude-dir' parameter per line, so that a directory name
#     containing spaces survives being read back into an array.
##
file_dir_exclude_params() {
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
  mapfile -t exclude_params < <(file_dir_exclude_params)

  if grep -rI "${exclude_params[@]}" -l "${string}" "${dir}"; then
    return 0
  else
    format_error "Directory does not contain string" "directory" "${dir}" "string" "${string}" | flunk
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
  mapfile -t exclude_params < <(file_dir_exclude_params)

  if grep -rI "${exclude_params[@]}" -l "${string}" "${dir}"; then
    format_error "Directory contains string, but should not" "directory" "${dir}" "string" "${string}" | flunk
  else
    return 0
  fi
}

##
# Raises the error a comparison command reported instead of comparing files.
#
# 'diff' and 'cmp' both answer "the files differ" with status 1 and report a
# failure of their own with a higher one. Reading the two the same way would let
# an unreadable file satisfy an assertion that the files differ.
#
# Arguments:
#   1. status: Status the comparison command exited with.
#   2. message: What it wrote while exiting.
#
# Returns:
#   0 when the status is a comparison result, non-zero via 'flunk' when it is
#   not.
##
file_compare_failed() {
  [ "${1}" -le 1 ] && return 0

  flunk "Unable to compare the files. ${2}"
}

##
# Asserts that the contents of two text files are equal.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
#   3. ignore_spaces: Set to '1' to ignore blank lines and whitespace changes.
#      Optional, defaults to '0'. Deprecated, use
#      'assert_files_equal_ignore_spaces' instead.
#
# Globals:
#   BATS_HELPERS_DEPRECATION_QUIET: Non-empty suppresses this library's
#     deprecation notices.
##
assert_files_equal() {
  local ignore_spaces="${3:-0}"

  if [ "${ignore_spaces}" = 1 ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: the 'ignore_spaces' argument of 'assert_files_equal' will be removed in the next version. Use 'assert_files_equal_ignore_spaces' instead." >&3
  fi

  file_assert_equal 0 "${ignore_spaces}" "${1}" "${2}"
}

##
# Asserts that two text files are equal, ignoring whitespace.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
##
assert_files_equal_ignore_spaces() {
  file_assert_equal 0 1 "${1}" "${2}"
}

##
# Asserts that the contents of two text files are not equal.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
#   3. ignore_spaces: Set to '1' to ignore blank lines and whitespace changes.
#      Optional, defaults to '0'. Deprecated, use
#      'assert_files_not_equal_ignore_spaces' instead.
#
# Globals:
#   BATS_HELPERS_DEPRECATION_QUIET: Non-empty suppresses this library's
#     deprecation notices.
##
assert_files_not_equal() {
  local ignore_spaces="${3:-0}"

  if [ "${ignore_spaces}" = 1 ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: the 'ignore_spaces' argument of 'assert_files_not_equal' will be removed in the next version. Use 'assert_files_not_equal_ignore_spaces' instead." >&3
  fi

  file_assert_equal 1 "${ignore_spaces}" "${1}" "${2}"
}

##
# Asserts that two text files are not equal, ignoring whitespace.
#
# Arguments:
#   1. file1: First file.
#   2. file2: Second file.
##
assert_files_not_equal_ignore_spaces() {
  file_assert_equal 1 1 "${1}" "${2}"
}

##
# Asserts that two text files are equal, reporting the difference on failure.
#
# Arguments:
#   1. negate: '1' to assert that the files differ.
#   2. ignore_spaces: '1' to ignore blank lines and whitespace changes.
#   3. file1: First file.
#   4. file2: Second file.
##
file_assert_equal() {
  local negate="${1}"
  local ignore_spaces="${2}"
  local file1="${3}"
  local file2="${4}"

  local -a diff_opts=(--normal)
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  local difference
  local compare_status=0
  difference="$(diff "${diff_opts[@]}" "${file1}" "${file2}" 2>&1)" || compare_status=$?

  # A comparison that could not run is checked before the outcome, so that its
  # status is never read as a difference between the files.
  file_compare_failed "${compare_status}" "${difference}" || return 1

  if [ "${negate}" = 1 ]; then
    [ "${compare_status}" -ne 0 ] && return 0

    format_error "Files are equal, but should not be" "file" "${file1}" "other file" "${file2}" | flunk

    return 1
  fi

  [ "${compare_status}" -eq 0 ] && return 0

  format_error "Files are not equal" "file" "${file1}" "other file" "${file2}" "difference" "${difference}" | flunk

  return 1
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

  local difference
  local compare_status=0
  difference="$(cmp "${file1}" "${file2}" 2>&1)" || compare_status=$?

  file_compare_failed "${compare_status}" "${difference}" || return 1

  [ "${compare_status}" -eq 0 ] && return 0

  format_error "Files are not equal" "file" "${file1}" "other file" "${file2}" "difference" "${difference}" | flunk
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

  local difference
  local compare_status=0
  difference="$(cmp "${file1}" "${file2}" 2>&1)" || compare_status=$?

  file_compare_failed "${compare_status}" "${difference}" || return 1

  [ "${compare_status}" -ne 0 ] && return 0

  format_error "Files are equal, but should not be" "file" "${file1}" "other file" "${file2}" | flunk
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

  assert_dir_exists "${dir1}" || return 1
  assert_dir_exists "${dir2}" || return 1

  file_dirs_equal_one_way "${dir1}" "${dir2}" || return 1
  file_dirs_equal_one_way "${dir2}" "${dir1}" || return 1

  return 0
}

##
# Asserts that every file of one directory has an equal counterpart in another.
#
# Arguments:
#   1. dir: Directory to walk.
#   2. other: Directory the counterpart is expected in.
##
file_dirs_equal_one_way() {
  local dir="${1}"
  local other="${2}"

  local file
  while IFS= read -r -d '' file; do
    local counterpart="${other}/${file#"${dir}/"}"

    if [ ! -e "${counterpart}" ]; then
      format_error "Directory holds a file the other directory does not" "file" "${file}" "directory" "${dir}" "other directory" "${other}" | flunk
      return 1
    fi

    assert_binary_files_equal "${file}" "${counterpart}" || return 1
  done < <(find "${dir}/" -type f -print0)

  return 0
}
