#!/usr/bin/env bats
#
# Tests for Bats helpers.
#
# shellcheck disable=SC2129

load _test_helper

@test "bats_internals" {
  echo "Bats version ${BATS_VERSION}" >&3
  [ "${BATS_FILE_TMPDIR}" != "" ]
  [ "${BATS_TEST_TMPDIR}" != "" ]
  [ "${BATS_SUITE_TMPDIR}" != "" ]
}
