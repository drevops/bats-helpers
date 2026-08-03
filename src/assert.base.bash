#!/usr/bin/env bash
##
# @file
# Failure reporting and error message formatting.
#

##
# Fails the test with a message.
#
# Arguments:
#   1. message: Message to print. Optional, read from STDIN when omitted.
#
# Outputs:
#   STDERR: The message, with occurrences of the test temporary directory path
#           replaced by the variable name so that messages stay comparable
#           between runs.
#
# Returns:
#   1 always.
##
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

##
# Formats an error message with a border and the captured output and stderr.
#
# Arguments:
#   1. message: Message to format.
#
# Globals:
#   output: Output captured by the last 'run' call. Appended when not empty.
#   stderr: Standard error captured by the last 'run --separate-stderr' call.
#     Appended when not empty.
#
# Outputs:
#   STDOUT: The formatted message.
##
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

  if [ "${stderr-}" != "" ]; then
    echo "----------------------------------------"
    echo "stderr:"
    echo "${stderr}"
    echo "----------------------------------------"
  fi
}
