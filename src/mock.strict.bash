#!/usr/bin/env bash
##
# @file
# Verification of the expectations declared on a mock.
#
# An expectation is a response configured for one call index or an argument
# specification. A mock with no expectations records calls without constraining
# them; a mock with at least one expectation rejects the calls that none of
# them covers, unless a response set without a call index has declared a
# catch-all.
#
# 'mock_expect_ordinal' is called while the test configures a mock, and
# 'mock_strict_accepts' and 'mock_strict_reject' run inside the mock's own
# process, where the assertion helpers are not loaded, so none of the three may
# call 'flunk'.
#

##
# Rejects the calls a mock's expectations do not cover.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. enabled: '1' to reject, '0' to answer every call. Optional, defaults
#      to '1'.
##
mock_set_strict() {
  local mock="${1?'Mock must be specified'}"
  local enabled="${2:-1}"

  if [ ! -e "${mock}" ]; then
    flunk "Mock '${mock}' does not exist. Create it with 'mock_command' first."
    return 1
  fi

  if [ "${enabled}" != "0" ] && [ "${enabled}" != "1" ]; then
    flunk "Strictness must be '0' or '1', got '${enabled}'."
    return 1
  fi

  echo -n "${enabled}" >"${mock}.strict"
}

##
# Reports whether a mock rejects the calls its expectations do not cover.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_strict_enabled() {
  local mock="${1}"

  [ -e "${mock}.strict" ] || return 1

  [ "$(cat "${mock}.strict")" = "1" ]
}

##
# Records that a response was configured for a call index.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. n: Index of the call.
##
mock_expect_ordinal() {
  local mock="${1}"
  local n="${2}"
  local file="${mock}.expect_ordinal"

  local recorded
  if [ -e "${file}" ]; then
    while IFS= read -r recorded; do
      [ "${recorded}" = "${n}" ] && return 0
    done <"${file}"
  fi

  printf '%s\n' "${n}" >>"${file}"
}

##
# Reports whether a mock has any expectation.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_has_expectations() {
  local mock="${1}"

  [ -e "${mock}.expect_ordinal" ] && return 0
  [ -e "${mock}.spec_num" ] && return 0

  return 1
}

##
# Reports whether a mock answers a call no expectation covers.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_strict_accepts() {
  local mock="${1}"

  mock_strict_enabled "${mock}" || return 0
  [ -e "${mock}.default" ] && return 0
  mock_has_expectations "${mock}" || return 0

  return 1
}

##
# Records a call that no expectation covers.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. name: Command name.
#   3. line: The call, serialised by 'mock_log_line'.
#
# Outputs:
#   STDERR: A diagnostic naming the call and every specification that turned
#           it down.
##
mock_strict_reject() {
  local mock="${1}"
  local name="${2}"
  local line="${3}"

  echo "Mock '${name}' received a call that no expectation covers: ${line}" >&2
  mock_spec_describe_all "${mock}" >&2

  printf '%s\n' "${line}" >>"${mock}.unexpected"
}

##
# Asserts that every expectation of every mock was met.
#
# Arguments:
#   1+. Mocks to verify. Optional, defaults to every mock of the test.
##
mock_verify() {
  local -a mocks=()

  if [ "$#" -gt 0 ]; then
    mocks=("$@")
  else
    mapfile -t mocks < <(mock_paths)
  fi

  local mock
  for mock in ${mocks[@]+"${mocks[@]}"}; do
    if [ ! -e "${mock}.call_num" ]; then
      flunk "Mock '${mock}' does not exist. Create it with 'mock_command' first."
      return 1
    fi
  done

  local -a problems=()
  local problem

  for mock in ${mocks[@]+"${mocks[@]}"}; do
    while IFS= read -r problem; do
      problems+=("${problem}")
    done < <(mock_verify_mock "${mock}")
  done

  [ "${#problems[@]}" -eq 0 ] && return 0

  local message
  printf -v message '%s\n' "${problems[@]}"

  format_error "${message%$'\n'}" | flunk
}

##
# Prints the unmet expectations of one mock.
#
# Arguments:
#   1. mock: Path to the mock.
#
# Outputs:
#   STDOUT: One line per unmet expectation, and nothing when all of them
#           were met.
##
mock_verify_mock() {
  local mock="${1}"

  local name
  name="$(cat "${mock}.name")"

  if [ -e "${mock}.unexpected" ]; then
    local line
    while IFS= read -r line; do
      echo "Mock '${name}' received a call that no expectation covers: ${line}"
    done <"${mock}.unexpected"

    mock_spec_describe_all "${mock}"
  fi

  local call_num
  call_num="$(cat "${mock}.call_num")"

  if [ -e "${mock}.expect_ordinal" ]; then
    local ordinal
    while IFS= read -r ordinal; do
      [ "${ordinal}" -le "${call_num}" ] && continue
      echo "Mock '${name}' has a response configured for call ${ordinal}, but was called ${call_num} time(s)"
    done <"${mock}.expect_ordinal"
  fi

  [ -e "${mock}.spec_num" ] || return 0

  local spec_num
  spec_num="$(cat "${mock}.spec_num")"

  local i
  for ((i = 1; i <= spec_num; i++)); do
    [ "$(cat "${mock}.spec.${i}.hits")" = "0" ] || continue
    echo "Mock '${name}' argument specification ${i} never accepted a call"
  done

  return 0
}
