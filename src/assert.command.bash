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
# Asserts that a needle matches a captured stream.
#
# Arguments:
#   1. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   2. negate: '1' to assert that the needle does not match.
#   3. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   4. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   5. haystack: Captured stream to search.
#   6. needle: String to search for. Optional, read from STDIN when omitted.
##
command_assert_match() {
  local needle

  if [ "$#" -eq 5 ]; then
    needle="$(cat -)"
  elif [ "$#" -eq 6 ]; then
    needle="${6}"
  else
    flunk "A needle is required."
    return 1
  fi

  string_assert_match "${1}" "${2}" "${3}" "${4}" "${5}" "${needle}"
}

##
## Output containment assertions.
##

##
# Asserts that the output of the last command contains a string, ignoring case.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_contains() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 0 "literal" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command contains a string,
# case-sensitively.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_contains_case() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 0 "literal" 1 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not contain a string,
# ignoring case.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_contains() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 1 "literal" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not contain a string,
# case-sensitively.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_contains_case() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 1 "literal" 1 "${output-}" "$@"
}

##
## Output regular expression assertions.
##

##
# Asserts that the output of the last command matches a regular expression,
# ignoring case.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 0 "regex" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command matches a regular expression,
# case-sensitively.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches_case() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 0 "regex" 1 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a regular
# expression, ignoring case.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 1 "regex" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a regular
# expression, case-sensitively.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches_case() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 1 "regex" 1 "${output-}" "$@"
}

##
## Output format assertions.
##

##
# Asserts that the output of the last command matches a format string, ignoring
# case.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches_format() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 0 "format" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command matches a format string,
# case-sensitively.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches_format_case() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 0 "format" 1 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a format string,
# ignoring case.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches_format() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 1 "format" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a format string,
# case-sensitively.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches_format_case() {
  # shellcheck disable=SC2154
  command_assert_match "anywhere" 1 "format" 1 "${output-}" "$@"
}

##
## Standard error assertions.
##

##
# Asserts that standard error was captured separately from the output.
#
# Only 'run --separate-stderr' populates 'stderr'. The check is that the
# variable is set rather than that it holds text, so that a command which wrote
# nothing to standard error is told apart from one whose standard error was
# never captured at all.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_captured() {
  if [ -z "${stderr+set}" ]; then
    flunk "Stderr was not captured. Run the command with 'run --separate-stderr'."
    return 1
  fi
}

##
# Asserts that the standard error of the last command equals a string.
#
# Arguments:
#   1. expected: Expected standard error. Optional, read from STDIN when
#      omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr() {
  assert_stderr_captured || return 1

  local expected
  if [ "$#" -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi

  assert_equal "${expected}" "${stderr}"
}

##
# Asserts that the last command wrote nothing to standard error.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_empty() {
  assert_stderr_captured || return 1

  assert_empty "${stderr}"
}

##
## Standard error containment assertions.
##

##
# Asserts that the standard error of the last command contains a string,
# ignoring case.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_contains() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 0 "literal" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command contains a string,
# case-sensitively.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_contains_case() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 0 "literal" 1 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not contain a string,
# ignoring case.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_contains() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 1 "literal" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not contain a string,
# case-sensitively.
#
# Arguments:
#   1. expected: String to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_contains_case() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 1 "literal" 1 "${stderr}" "$@"
}

##
## Standard error regular expression assertions.
##

##
# Asserts that the standard error of the last command matches a regular
# expression, ignoring case.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 0 "regex" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command matches a regular
# expression, case-sensitively.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches_case() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 0 "regex" 1 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a regular
# expression, ignoring case.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 1 "regex" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a regular
# expression, case-sensitively.
#
# Arguments:
#   1. expected: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches_case() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 1 "regex" 1 "${stderr}" "$@"
}

##
## Standard error format assertions.
##

##
# Asserts that the standard error of the last command matches a format string,
# ignoring case.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches_format() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 0 "format" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command matches a format string,
# case-sensitively.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches_format_case() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 0 "format" 1 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a format
# string, ignoring case.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches_format() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 1 "format" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a format
# string, case-sensitively.
#
# Arguments:
#   1. expected: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches_format_case() {
  assert_stderr_captured || return 1

  command_assert_match "anywhere" 1 "format" 1 "${stderr}" "$@"
}
