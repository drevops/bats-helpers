#!/usr/bin/env bash
##
# @file
# Bats test helpers to run commands.
#

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
  assert_contains "${expected}" "${output-}"
}

assert_output_not_contains() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="${1}"
  fi
  # shellcheck disable=SC2154
  assert_not_contains "${expected}" "${output-}"
}
