#!/usr/bin/env bash
##
# @file
# Common setup for the library's own tests.
#

# Load library.
load '../load.bash'

setup() {
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
