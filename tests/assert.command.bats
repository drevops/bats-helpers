#!/usr/bin/env bats
#
# Tests for command assertions.
#
# shellcheck disable=SC2129

load _test_helper

# Passing flags to 'run' warns below this version.
bats_require_minimum_version 1.5.0

@test "assert_success" {
  status=0
  assert_success

  status=1
  run assert_success
  [ "${status}" -eq 1 ]
  assert_output_contains "Command failed with exit status 1"
  assert_output_not_contains "stderr:"

  stderr="stderr needle"
  status=1
  run assert_success
  [ "${status}" -eq 1 ]
  assert_output_contains "stderr needle"
}

@test "assert_failure" {
  status=1
  assert_failure

  status=0
  run assert_failure
  [ "${status}" -eq 1 ]
  assert_output_contains "Command succeeded, but should have failed"
  assert_output_not_contains "stderr:"

  stderr="stderr needle"
  status=0
  run assert_failure
  [ "${status}" -eq 1 ]
  assert_output_contains "stderr needle"
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

@test "assert_stderr_captured" {
  run --separate-stderr bash -c 'echo "some error" >&2'
  assert_stderr_captured

  # A command that wrote nothing to STDERR was still captured.
  run --separate-stderr echo "some output"
  assert_stderr_captured

  unset stderr
  run assert_stderr_captured
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr" {
  run --separate-stderr bash -c 'echo "some output"; echo "some error" >&2'
  assert_stderr "some error"
  assert_output "some output"

  run assert_stderr "some other error"
  assert_failure

  unset stderr
  run assert_stderr "some error"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_contains" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_contains "some existing error"
  assert_stderr_contains "some EXISTING error"
  assert_stderr_contains "existing"

  run assert_stderr_contains "non-existing"
  assert_failure

  unset stderr
  run assert_stderr_contains "existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_contains" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_contains "non-existing"

  run assert_stderr_not_contains "some existing error"
  assert_failure

  run assert_stderr_not_contains "some EXISTING error"
  assert_failure

  run assert_stderr_not_contains "existing"
  assert_failure

  unset stderr
  run assert_stderr_not_contains "non-existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_empty" {
  run --separate-stderr echo "some output"
  assert_stderr_empty

  run --separate-stderr bash -c 'echo "some error" >&2'
  run assert_stderr_empty
  assert_failure

  unset stderr
  run assert_stderr_empty
  assert_failure
  assert_output_contains "run --separate-stderr"
}
