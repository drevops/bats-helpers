#!/usr/bin/env bats
#
# Tests for Bats helpers.
#
# Each assertion tests positive and negative behaviour.
#
# shellcheck disable=SC2129

load _test_helper

@test "bats_internals" {
  echo "Bats version ${BATS_VERSION}" >&3
  [ "${BATS_FILE_TMPDIR}" != "" ]
  [ "${BATS_TEST_TMPDIR}" != "" ]
  [ "${BATS_SUITE_TMPDIR}" != "" ]
}

@test "assert_success" {
  status=0
  assert_success

  status=1
  run assert_success
  [ "$status" -eq 1 ]
}

@test "assert_failure" {
  status=1
  assert_failure

  status=0
  run assert_failure
  [ "$status" -eq 1 ]
}

@test "assert_output" {
  output="output needle"
  assert_output "output needle"

  output="output not needle"
  run assert_output "output needle"
  assert_failure
}

@test "assert_output_contains" {
  run echo "some existing text"
  assert_output_contains "some existing text"

  run echo "some existing text"
  assert_output_contains "some EXISTING text"

  run echo "some existing text"
  assert_output_contains "existing"

  run assert_output_contains "non-existing"
  assert_failure
}

@test "assert_output_not_contains" {
  run echo "some existing text"
  assert_output_not_contains "non-existing"

  run assert_output_not_contains "some existing text"
  assert_failure

  run assert_output_not_contains "some EXISTING text"
  assert_failure

  run assert_output_not_contains "existing"
  assert_failure
}

@test "assert_equal" {
  assert_equal 1 1

  run assert_equal 1 2
  assert_failure
}

@test "assert_empty" {
  assert_empty ""

  run assert_empty "something"
  assert_failure
}

@test "assert_not_empty" {
  assert_not_empty "something"

  run assert_not_empty ""
  assert_failure
}
