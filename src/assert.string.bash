#!/usr/bin/env bash
##
# @file
# Assertions for strings.
#

##
# Asserts that a string is empty.
#
# Arguments:
#   1. string: String to check.
##
assert_empty() {
  if [ "${1-}" = "" ]; then
    return 0
  else
    format_error "String '${1}' is not empty" | flunk
  fi
}

##
# Asserts that a string is not empty.
#
# Arguments:
#   1. string: String to check.
##
assert_not_empty() {
  if [ "${1-}" = "" ]; then
    format_error "String '${1}' is empty, but should not be" | flunk
  else
    return 0
  fi
}

##
# Asserts that a string contains a substring.
#
# The match is case-insensitive and treats the needle as a literal string.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_contains() {
  local haystack="${1}"
  local needle="${2}"

  if echo "${haystack}" | $(type -p grep | head -1) -i -F -- "${needle}" >/dev/null; then
    return 0
  else
    format_error "String '${haystack}' does not contain '${needle}'" | flunk
  fi
}

##
# Asserts that a string does not contain a substring.
#
# The match is case-insensitive and treats the needle as a literal string.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_contains() {
  local haystack="${1}"
  local needle="${2}"

  if echo "${haystack}" | $(type -p grep | head -1) -i -F -- "${needle}" >/dev/null; then
    format_error "String '${haystack}' contains '${needle}', but should not" | flunk
  else
    return 0
  fi
}

##
# Asserts that two strings are equal.
#
# Arguments:
#   1. expected: Expected string.
#   2. actual: Actual string.
##
assert_equal() {
  if [ "${1-}" != "${2-}" ]; then
    {
      echo "expected: ${1}"
      echo "actual:   ${2}"
    } | flunk
  fi
}

##
# Generates a random alphanumeric string.
#
# Arguments:
#   1. length: Number of characters to generate. Optional, defaults to 8.
#
# Outputs:
#   STDOUT: The generated string.
##
string_random() {
  local len="${1:-8}"
  local alphabet='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local ret=''
  local i

  if ! [[ ${len} =~ ^[0-9]+$ ]]; then
    flunk "Length must be a non-negative integer."
    return 1
  fi

  # Base 10 is explicit so that a zero-padded length is not read as octal.
  len=$((10#${len}))

  # A '/dev/urandom' pipeline is not usable here: its tools' STDERR reaches the
  # caller, where Bats' 'run' merges it into the returned value, and its reader
  # can outlive the writer and hang.
  for ((i = 0; i < len; i++)); do
    ret="${ret}${alphabet:RANDOM%${#alphabet}:1}"
  done

  echo "${ret}"
}

##
## Deprecated aliases, removed in the next version.
##

assert_contains() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_contains' will be removed in the next version. Use 'assert_string_contains' instead." >&3
  assert_string_contains "${2-}" "${1-}"
}

assert_not_contains() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_not_contains' will be removed in the next version. Use 'assert_string_not_contains' instead." >&3
  assert_string_not_contains "${2-}" "${1-}"
}

random_string() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'random_string' will be removed in the next version. Use 'string_random' instead." >&3
  string_random "$@"
}
