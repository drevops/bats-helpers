#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2294

flunk() {
  {
    if [ "$#" -eq 0 ]; then
      cat -
    else
      echo "$@"
    fi
  } | sed "s:${BATS_TEST_TMPDIR}:\${BATS_TEST_TMPDIR}:g" >&2
  return 1
}

assert_success() {
  # shellcheck disable=SC2154
  if [ "${status-}" -ne 0 ]; then
    format_error "command failed with exit status ${status}" | flunk
  elif [ "$#" -gt 0 ]; then
    assert_output "${1}"
  fi
}

assert_failure() {
  # shellcheck disable=SC2154
  if [ "${status-}" -eq 0 ]; then
    format_error "expected failed exit status" | flunk
  elif [ "$#" -gt 0 ]; then
    assert_output "${1}"
  fi
}

assert_equal() {
  if [ "${1-}" != "${2-}" ]; then
    {
      echo "expected: ${1}"
      echo "actual:   ${2}"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_equal "${expected}" "${output}"
}

assert_output_contains() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_contains "${expected}" "${output}"
}

assert_output_not_contains() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_not_contains "${expected}" "${output}"
}

assert_empty() {
  if [ "${1-}" = "" ]; then
    return 0
  else
    format_error "String ${1} is not empty, but should be" | flunk
  fi
}

assert_not_empty() {
  if [ "${1-}" = "" ]; then
    format_error "String ${1} is empty, but should not be" | flunk
  else
    return 0
  fi
}

# Format error message with optional output, if present.
format_error() {
  local message="${1}"
  echo "##################################################"
  echo "#             BEGIN ERROR MESSAGE                #"
  echo "##################################################"
  echo
  echo "${message}"
  echo
  echo "##################################################"
  echo "#              END ERROR MESSAGE                 #"
  echo "##################################################"
  echo

  if [ "${output-}" != "" ]; then
    echo "----------------------------------------"
    echo "${BATS_TEST_TMPDIR}"
    echo "${output}"
    echo "----------------------------------------"
  fi
}

# Run bats with `--tap` option to debug the output.
debug() {
  echo "${1}" >&3
}
