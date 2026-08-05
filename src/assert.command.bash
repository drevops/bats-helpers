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
#   output: Output captured by the last 'run' call.
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_success() {
  # shellcheck disable=SC2154
  if [ "${status-}" -ne 0 ]; then
    local -a rows=("status" "$(command_describe_status "${status}")")
    [ -z "${output-}" ] || rows+=("output" "${output}")
    [ -z "${stderr-}" ] || rows+=("stderr" "${stderr}")

    format_error "Command failed" "${rows[@]}" | flunk
  elif [ "$#" -gt 0 ]; then
    assert_output "${1}"
  fi
}

##
# Asserts that the last command failed.
#
# Arguments:
#   1. --status expected: Exact exit status to assert on, as two arguments.
#      Optional, recognised only in first position. Deprecated, use
#      'assert_failure_status' instead.
#   2. output: Exact output to additionally assert on. Optional.
#
# Globals:
#   status: Exit status of the last 'run' call.
#   output: Output captured by the last 'run' call.
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
#   BATS_HELPERS_DEPRECATION_QUIET: Non-empty suppresses this library's
#     deprecation notices.
##
assert_failure() {
  local expected=""

  if [ "${1-}" = "--status" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_failure --status' will be removed in the next version. Use 'assert_failure_status' instead." >&3

    if [ "$#" -lt 2 ]; then
      flunk "Option '--status' requires an exit status."
      return 1
    fi

    command_validate_status "${2}" || return 1

    if [ "${2}" -eq 0 ]; then
      flunk "A failure cannot have exit status 0. Use 'assert_success' instead."
      return 1
    fi

    expected="${2}"
    shift 2
  fi

  # shellcheck disable=SC2154
  if [ "${status-}" -eq 0 ]; then
    local -a rows=()
    [ -z "${output-}" ] || rows+=("output" "${output}")
    [ -z "${stderr-}" ] || rows+=("stderr" "${stderr}")

    format_error "Command succeeded, but should have failed" "${rows[@]}" | flunk
    return 1
  fi

  if [ -n "${expected}" ]; then
    assert_status "${expected}" || return 1
  fi

  if [ "$#" -gt 0 ]; then
    assert_output "${1}"
  fi
}

##
# Asserts that the last command failed with an exact exit status.
#
# Arguments:
#   1. expected: Exit status to assert on.
#   2. output: Exact output to additionally assert on. Optional.
#
# Globals:
#   status: Exit status of the last 'run' call.
#   output: Output captured by the last 'run' call.
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_failure_status() {
  command_validate_status "${1-}" || return 1

  if [ "${1}" -eq 0 ]; then
    flunk "A failure cannot have exit status 0. Use 'assert_success' instead."
    return 1
  fi

  local expected="${1}"
  shift

  assert_failure "$@" || return 1
  assert_status "${expected}"
}

##
## Exit status assertions.
##

##
# Asserts that the last command exited with an exact status.
#
# Arguments:
#   1. expected: Expected exit status.
#
# Globals:
#   status: Exit status of the last 'run' call.
#   output: Output captured by the last 'run' call.
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_status() {
  if [ "$#" -eq 0 ]; then
    flunk "An expected exit status is required."
    return 1
  fi

  command_validate_status "${1}" || return 1

  # shellcheck disable=SC2154
  if [ "${status-}" -eq "${1}" ]; then
    return 0
  fi

  local -a rows=("expected" "${1}" "actual" "$(command_describe_status "${status}")")
  [ "${output-}" = "" ] || rows+=("output" "${output}")
  [ "${stderr-}" = "" ] || rows+=("stderr" "${stderr}")

  format_error "Command exited with an unexpected status" "${rows[@]}" | flunk
}

##
# Asserts that the last command exited with the general error status.
#
# Globals:
#   status: Exit status of the last 'run' call.
##
assert_status_general_error() {
  assert_status 1
}

##
# Asserts that the last command exited with the command not found status.
#
# Globals:
#   status: Exit status of the last 'run' call.
##
assert_status_command_not_found() {
  assert_status 127
}

##
# Validates a value given as an expected exit status.
#
# Arguments:
#   1. expected: Value to validate.
##
command_validate_status() {
  if ! [[ ${1-} =~ ^[0-9]+$ ]] || [ "${1}" -gt 255 ]; then
    flunk "Exit status '${1-}' is not an integer between 0 and 255."
    return 1
  fi
}

##
# Describes an exit status, naming the ones that mean more than a failure.
#
# A status of 127 is what a shell returns for a command it could not find, and a
# status above 128 is how it reports a process a signal killed rather than one
# that chose its own status. Either reads as an ordinary failure of the code
# under test unless it is named.
#
# Arguments:
#   1. status: Exit status to describe.
#
# Outputs:
#   STDOUT: The status, followed by what it means when it means something.
##
command_describe_status() {
  local code="${1}"

  if [ "${code}" -eq 127 ]; then
    printf '%s (command not found)\n' "${code}"
    return 0
  fi

  local signal=$((code - 128))

  if [ "${signal}" -ge 1 ]; then
    local name
    # A number the platform does not name is not one of its signals, so the
    # status is left to stand for itself rather than named as one.
    if name="$(kill -l "${signal}" 2>/dev/null)" && [ -n "${name}" ]; then
      printf '%s (killed by SIG%s)\n' "${code}" "${name}"
      return 0
    fi
  fi

  printf '%s\n' "${code}"
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
  # shellcheck disable=SC2154
  command_assert_equal "output" "${output-}" "$@"
}

##
# Asserts that a needle matches a captured stream.
#
# Arguments:
#   1. subject: Which stream the haystack is - 'output' or 'stderr'. Opens the
#      title and keys the row the stream is reported under.
#   2. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   3. negate: '1' to assert that the needle does not match.
#   4. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   5. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   6. haystack: Captured stream to search.
#   7. needle: String to search for. Optional, read from STDIN when omitted.
##
command_assert_match() {
  local needle

  if [ "$#" -eq 6 ]; then
    needle="$(cat -)"
  elif [ "$#" -eq 7 ]; then
    needle="${7}"
  else
    flunk "A needle is required."
    return 1
  fi

  string_assert_match "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${needle}"
}

##
# Asserts that a captured stream equals a string.
#
# Arguments:
#   1. subject: Which stream the value is - 'output' or 'stderr'. Opens the
#      title of the report.
#   2. actual: Captured stream to compare.
#   3. expected: Expected value. Optional, read from STDIN when omitted.
##
command_assert_equal() {
  local subject="${1}"
  local actual="${2}"

  local expected
  if [ "$#" -eq 2 ]; then
    expected="$(cat -)"
  else
    expected="${3}"
  fi

  if [ "${expected}" = "${actual}" ]; then
    return 0
  fi

  format_error "$(string_subject_noun "${subject}") does not equal string" "expected" "${expected}" "actual" "${actual}" | flunk
}

##
## Output containment assertions.
##

##
# Asserts that the output of the last command contains a substring,
# ignoring case.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_contains() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 0 "literal" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command contains a substring,
# case-sensitively.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_contains_case() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 0 "literal" 1 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not contain a substring,
# ignoring case.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_contains() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 1 "literal" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not contain a substring,
# case-sensitively.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_contains_case() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 1 "literal" 1 "${output-}" "$@"
}

##
## Output regular expression assertions.
##

##
# Asserts that the output of the last command matches a regular expression,
# ignoring case.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 0 "regex" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command matches a regular expression,
# case-sensitively.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches_case() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 0 "regex" 1 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a regular
# expression, ignoring case.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 1 "regex" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a regular
# expression, case-sensitively.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches_case() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 1 "regex" 1 "${output-}" "$@"
}

##
## Output format assertions.
##

##
# Asserts that the output of the last command matches a format string, ignoring
# case.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches_format() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 0 "format" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command matches a format string,
# case-sensitively.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_matches_format_case() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 0 "format" 1 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a format string,
# ignoring case.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches_format() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 1 "format" 0 "${output-}" "$@"
}

##
# Asserts that the output of the last command does not match a format string,
# case-sensitively.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   output: Output captured by the last 'run' call.
##
assert_output_not_matches_format_case() {
  # shellcheck disable=SC2154
  command_assert_match "output" "anywhere" 1 "format" 1 "${output-}" "$@"
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

  command_assert_equal "stderr" "${stderr}" "$@"
}

##
# Asserts that the last command wrote nothing to standard error.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_empty() {
  assert_stderr_captured || return 1

  if [ -z "${stderr}" ]; then
    return 0
  else
    format_error "Stderr is not empty" "stderr" "${stderr}" | flunk
  fi
}

##
## Standard error containment assertions.
##

##
# Asserts that the standard error of the last command contains a substring,
# ignoring case.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_contains() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 0 "literal" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command contains a substring,
# case-sensitively.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_contains_case() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 0 "literal" 1 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not contain
# a substring, ignoring case.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_contains() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 1 "literal" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not contain
# a substring, case-sensitively.
#
# Arguments:
#   1. needle: Substring to search for. Optional, read from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_contains_case() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 1 "literal" 1 "${stderr}" "$@"
}

##
## Standard error regular expression assertions.
##

##
# Asserts that the standard error of the last command matches a regular
# expression, ignoring case.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 0 "regex" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command matches a regular
# expression, case-sensitively.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches_case() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 0 "regex" 1 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a regular
# expression, ignoring case.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 1 "regex" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a regular
# expression, case-sensitively.
#
# Arguments:
#   1. needle: Extended regular expression to match. Optional, read from STDIN
#      when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches_case() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 1 "regex" 1 "${stderr}" "$@"
}

##
## Standard error format assertions.
##

##
# Asserts that the standard error of the last command matches a format string,
# ignoring case.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches_format() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 0 "format" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command matches a format string,
# case-sensitively.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_matches_format_case() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 0 "format" 1 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a format
# string, ignoring case.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches_format() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 1 "format" 0 "${stderr}" "$@"
}

##
# Asserts that the standard error of the last command does not match a format
# string, case-sensitively.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'. Optional, read
#      from STDIN when omitted.
#
# Globals:
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
##
assert_stderr_not_matches_format_case() {
  assert_stderr_captured || return 1

  command_assert_match "stderr" "anywhere" 1 "format" 1 "${stderr}" "$@"
}
