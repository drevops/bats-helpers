#!/usr/bin/env bats
#
# Fixture for the deferred cleanup teardown tests.
#
# Run by the tests in 'tests/cleanup.bats', not by the suite.
#

load ../../load.bash

teardown() {
  cleanup_run
}

@test "passing test with a cleanup" {
  cleanup_register touch "${CLEANUP_FIXTURE_DIR}/passing.marker"
}

@test "failing test with a cleanup" {
  cleanup_register touch "${CLEANUP_FIXTURE_DIR}/failing.marker"

  false
}

@test "passing test with a failing cleanup" {
  cleanup_register false
}

@test "failing test with a failing cleanup" {
  cleanup_register false

  false
}
