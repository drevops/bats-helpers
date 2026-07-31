#!/usr/bin/env bash
##
# @file
# Assertions for commands executed with 'run'.
#

##
# Asserts that the last command succeeded.
#
# Arguments:
#   1. output: Exact output to additionally assert on. Optional.
#
# Globals:
#   status: Exit status of the last 'run' call.
##
assert_success() {
  # shellcheck disable=SC2154
  if [ "${status-}" -ne 0 ]; then
    format_error "Command failed with exit status ${status}" | flunk
  elif [ "$#" -gt 0 ]; then
    assert_output "${1}"
  fi
}

##
# Asserts that the last command failed.
#
# Arguments:
#   1. output: Exact output to additionally assert on. Optional.
#
# Globals:
#   status: Exit status of the last 'run' call.
##
assert_failure() {
  # shellcheck disable=SC2154
  if [ "${status-}" -eq 0 ]; then
    format_error "Command succeeded, but should have failed" | flunk
  elif [ "$#" -gt 0 ]; then
    assert_output "${1}"
  fi
}

##
# Asserts that the output of the last command equals a string.
#
# Arguments:
#   1. expected: Expected output. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output() {
  local expected
  if [ "$#" -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_equal "${expected}" "${output}"
}

##
# Asserts that the output of the last command contains a string.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_contains() {
  local expected
  if [ "$#" -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_string_contains "${output-}" "${expected}"
}

##
# Asserts that the output of the last command does not contain a string.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_contains() {
  local expected
  if [ "$#" -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_string_not_contains "${output-}" "${expected}"
}
