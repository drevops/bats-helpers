#!/usr/bin/env bash
##
# @file
# Common setup for the library's own tests.
#

# Load library.
load '../load.bash'

setup() {
  # MSYS 'ln -s' copies the target unless native links are enabled, so
  # symlink fixtures would be regular files. 'native' still copies where a
  # link is not permitted, rather than failing.
  # LCOV_EXCL_START
  case "$(uname)" in
    MINGW* | MSYS*) export MSYS="${MSYS:+${MSYS} }winsymlinks:native" ;;
  esac
  # LCOV_EXCL_STOP

  # Setup command mocking.
  mock_setup

  # Assertions on the rendered reports compare plain text, so the tests that
  # cover the colour decision itself opt back in rather than out.
  export BATS_HELPERS_REPORT_COLOR=0

  # Print debug information if "--verbose-run" is passed.
  # LCOV_EXCL_START
  if [ "${BATS_VERBOSE_RUN-}" = "1" ]; then
    echo "BATS_TEST_TMPDIR: ${BATS_TEST_TMPDIR}" >&3
  fi
  # LCOV_EXCL_STOP
}

teardown() {
  cleanup_run
}

##
# Runs a command with shell tracing on and appends the trace to a file.
#
# Arguments:
#   1. trace: File to append the trace to.
#   2. command: Command to run, followed by its arguments.
##
trace_run() {
  local trace="${1}"
  shift

  # The subshell keeps the outer trace descriptor, which kcov reads, open.
  (
    exec 3>>"${trace}"
    BASH_XTRACEFD=3
    PS4='+ '
    set -x
    "$@" || true
    set +x
  )
}

##
# Asserts that a trace holds a record and keeps each conditional on 1 line.
#
# Arguments:
#   1. trace: Trace file written by 'trace_run'.
#   2. record: Substring of a record the trace must hold.
##
assert_trace_single_line() {
  local trace="${1}"
  local record="${2}"
  local -a lines
  local line

  assert_file_contains_case "${trace}" "${record}"

  mapfile -t lines <"${trace}"

  # Bash before 5.3 traces a multi-line word in single quotes with its line
  # breaks intact, so only the '[[ ]]' records are checked for spanning lines.
  for line in "${lines[@]}"; do
    case "${line}" in *'[['*) assert_string_ends_with_case "${line}" "]]" ;; esac
  done
}
