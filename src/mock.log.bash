#!/usr/bin/env bash
##
# @file
# Ordered log of every mocked command call.
#
# 'mock_log_quote', 'mock_log_line' and 'mock_log_append' run inside the mock's
# own process, where the assertion helpers are not loaded, so none of them may
# call 'flunk'.
#

##
# Writes a value in the canonical serialisation of one call argument.
#
# The value is wrapped in single quotes so that an empty argument stays visible
# and one holding whitespace stays a single field. Inside the quotes a
# backslash reads '\\', a single quote reads '\'', a tab reads '\t' and a
# newline reads '\n', so every argument occupies exactly one line and no two
# distinct arguments serialise the same way.
#
# Arguments:
#   1. value: Argument value. Optional, defaults to an empty string.
#
# Outputs:
#   STDOUT: The quoted value.
##
mock_log_quote() {
  local value="${1-}"

  value="${value//\\/\\\\}"
  value="${value//\'/\\\'}"
  value="${value//$'\t'/\\t}"
  value="${value//$'\n'/\\n}"

  printf "'%s'" "${value}"
}

##
# Writes one call as a log line.
#
# Arguments:
#   1. name: Command name.
#   2+. Arguments the command was called with.
#
# Outputs:
#   STDOUT: The command name followed by every argument, each quoted by
#           'mock_log_quote'.
##
mock_log_line() {
  local name="${1}"
  shift

  local line="${name}"
  local argument

  for argument in ${@+"$@"}; do
    line="${line} $(mock_log_quote "${argument}")"
  done

  printf '%s\n' "${line}"
}

##
# Appends a line to the call log.
#
# Arguments:
#   1. log: Path to the log.
#   2. line: Line to append.
##
mock_log_append() {
  local log="${1}"
  local line="${2}"

  printf '%s\n' "${line}" >>"${log}"
}

##
# Resolves the path to the call log.
#
# Globals:
#   BATS_HELPERS_MOCK_TMPDIR: Directory the mocks are stored in.
#
# Outputs:
#   STDOUT: Path to the log, which does not exist until the first call.
##
mock_log_path() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  echo "${dir}/mock.log"
}

##
# Prints the call log.
#
# Outputs:
#   STDOUT: Every recorded call, in the order the calls were made, including
#           the ones excluded from sequence comparisons.
##
mock_log_print() {
  local log
  log="$(mock_log_path)" || return 1

  [ -e "${log}" ] || return 0

  cat "${log}"
}

##
# Excludes commands from sequence comparisons.
#
# The calls are still recorded and still visible to 'mock_log_print',
# 'mock_assert_called' and 'mock_assert_not_called'. Only 'mock_assert_calls'
# and 'mock_assert_no_calls' skip them.
#
# Arguments:
#   1+. Command names to exclude.
##
mock_log_exclude() {
  if [ "$#" -eq 0 ]; then
    flunk "At least one command name is required."
    return 1
  fi

  local log
  log="$(mock_log_path)" || return 1

  local name
  for name in "$@"; do
    printf '%s\n' "${name}" >>"${log}.excluded"
  done
}

##
# Prints the call log without the excluded commands.
#
# Outputs:
#   STDOUT: Every recorded call that 'mock_log_exclude' did not exclude.
##
mock_log_filtered() {
  local log
  log="$(mock_log_path)" || return 1

  [ -e "${log}" ] || return 0

  local -a excluded=()
  local name

  if [ -e "${log}.excluded" ]; then
    while IFS= read -r name; do
      [ -n "${name}" ] && excluded+=("${name}")
    done <"${log}.excluded"
  fi

  local line
  local candidate
  local skip

  while IFS= read -r line; do
    skip=0

    for candidate in ${excluded[@]+"${excluded[@]}"}; do
      [ "${line%% *}" = "${candidate}" ] && skip=1
    done

    [ "${skip}" = "1" ] && continue

    printf '%s\n' "${line}"
  done <"${log}"

  return 0
}

##
# Reports whether a command name belongs to a mock.
#
# Arguments:
#   1. name: Command name.
#
# Returns:
#   0 when a mock is registered under the name, 1 when none is.
##
mock_log_registered() {
  local name="${1}"
  local registered

  while IFS= read -r registered; do
    [ "${registered}" = "${name}" ] && return 0
  done < <(mock_names)

  return 1
}

##
## Assertions.
##

##
# Asserts that the mocked commands were called in the given order.
#
# Arguments:
#   1+. Expected calls, one per argument, each in the serialisation
#       'mock_log_quote' documents. No arguments asserts that nothing was
#       called.
##
mock_assert_calls() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local expected_file="${dir}/mock.log.expected"
  local actual_file="${dir}/mock.log.actual"

  echo -n '' >"${expected_file}"

  local expected_call
  for expected_call in ${@+"$@"}; do
    printf '%s\n' "${expected_call}" >>"${expected_file}"
  done

  mock_log_filtered >"${actual_file}" || return 1

  local report
  report="$(diff -u -L expected -L actual "${expected_file}" "${actual_file}")" && return 0

  format_error "Call log does not match the expected sequence"$'\n'"${report}" | flunk
}

##
# Asserts that no mocked command was called.
##
mock_assert_no_calls() {
  local actual
  actual="$(mock_log_filtered)" || return 1

  [ -z "${actual}" ] && return 0

  format_error "Mocked commands were called, but none should have been"$'\n'"${actual}" | flunk
}

##
# Asserts that a command was called.
#
# Arguments:
#   1. name: Command name.
##
mock_assert_called() {
  local name="${1?'Command name must be specified'}"

  mock_log_registered "${name}" || {
    flunk "Command '${name}' is not mocked. Register it with 'mock_command' first."
    return 1
  }

  local matched
  matched="$(mock_log_calls_of "${name}")" || return 1

  [ -n "${matched}" ] && return 0

  format_error "Command '${name}' was not called" | flunk
}

##
# Asserts that a command was not called.
#
# Arguments:
#   1. name: Command name.
##
mock_assert_not_called() {
  local name="${1?'Command name must be specified'}"

  mock_log_registered "${name}" || {
    flunk "Command '${name}' is not mocked. Register it with 'mock_command' first."
    return 1
  }

  local matched
  matched="$(mock_log_calls_of "${name}")" || return 1

  [ -z "${matched}" ] && return 0

  format_error "Command '${name}' was called, but should not have been"$'\n'"${matched}" | flunk
}

##
# Prints the recorded calls of one command.
#
# Arguments:
#   1. name: Command name.
#
# Outputs:
#   STDOUT: Every recorded call of the command, in the order the calls were
#           made.
##
mock_log_calls_of() {
  local name="${1}"
  local log
  log="$(mock_log_path)" || return 1

  [ -e "${log}" ] || return 0

  local line
  while IFS= read -r line; do
    [ "${line%% *}" = "${name}" ] && printf '%s\n' "${line}"
  done <"${log}"

  return 0
}
