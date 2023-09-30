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
