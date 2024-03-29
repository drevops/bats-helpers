#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2294

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

assert_contains() {
  local needle="${1}"
  local haystack="${2}"

  if echo "$haystack" | $(type -p grep | head -1) -i -F -- "$needle" >/dev/null; then
    return 0
  else
    format_error "String '${haystack}' does not contain '${needle}'" | flunk
  fi
}

assert_not_contains() {
  local needle="${1}"
  local haystack="${2}"

  if echo "$haystack" | $(type -p grep | head -1) -i -F -- "$needle" >/dev/null; then
    format_error "String '${haystack}' contains '${needle}', but should not" | flunk
  else
    return 0
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

random_string() {
  local len="${1:-8}"
  local ret
  # shellcheck disable=SC2002
  ret=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w "${len}" | head -n 1)
  echo "${ret}"
}
