#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#

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

assert_string_contains() {
  local haystack="${1}"
  local needle="${2}"

  if echo "${haystack}" | $(type -p grep | head -1) -i -F -- "${needle}" >/dev/null; then
    return 0
  else
    format_error "String '${haystack}' does not contain '${needle}'" | flunk
  fi
}

assert_string_not_contains() {
  local haystack="${1}"
  local needle="${2}"

  if echo "${haystack}" | $(type -p grep | head -1) -i -F -- "${needle}" >/dev/null; then
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

##
# Deprecated aliases, removed in the next version.
##

assert_contains() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_contains' will be removed in the next version. Use 'assert_string_contains' instead." >&3
  assert_string_contains "${2-}" "${1-}"
}

assert_not_contains() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_not_contains' will be removed in the next version. Use 'assert_string_not_contains' instead." >&3
  assert_string_not_contains "${2-}" "${1-}"
}
