#!/usr/bin/env bats
#
# Tests for command assertions.
#
# shellcheck disable=SC2129

load _test_helper

# Matches the library's minimum, and silences the warning flags on 'run' emit.
bats_require_minimum_version 1.13.0

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

  run echo "some existing text"
  assert_output_contains --case-sensitive "some existing text"

  run echo "some existing 42 text"
  assert_output_contains --regex 'existing [0-9]+'

  run echo "some existing 42 text"
  assert_output_contains --format "existing %d text"

  run echo "some existing text"
  assert_output_contains <<<"existing"

  run assert_output_contains "non-existing"
  assert_failure

  run echo "some EXISTING text"
  run assert_output_contains --case-sensitive "some existing text"
  assert_failure
}

@test "assert_output_not_contains" {
  run echo "some existing text"
  assert_output_not_contains "non-existing"

  run echo "some EXISTING text"
  assert_output_not_contains --case-sensitive "some existing text"

  run echo "some existing text"
  assert_output_not_contains --regex 'existing [0-9]+'

  run assert_output_not_contains "some existing text"
  assert_failure

  run assert_output_not_contains "some EXISTING text"
  assert_failure

  run assert_output_not_contains "existing"
  assert_failure

  run echo "some existing 42 text"
  run assert_output_not_contains --regex 'existing [0-9]+'
  assert_failure
}

@test "assert_output_matches" {
  run echo "some existing 42 text"
  assert_output_matches 'existing [0-9]+'
  assert_output_matches 'EXISTING [0-9]+'
  assert_output_matches '^some'
  assert_output_matches 'text$'
  assert_output_matches --case-sensitive 'existing [0-9]+'

  run echo "some existing 42 text"
  assert_output_matches <<<'existing [0-9]+'

  run echo "some existing text"
  run assert_output_matches 'existing [0-9]+'
  assert_failure

  run echo "some EXISTING 42 text"
  run assert_output_matches --case-sensitive 'existing [0-9]+'
  assert_failure
}

@test "assert_output_not_matches" {
  run echo "some existing text"
  assert_output_not_matches 'existing [0-9]+'

  run echo "some EXISTING 42 text"
  assert_output_not_matches --case-sensitive 'existing [0-9]+'

  run echo "some existing 42 text"
  run assert_output_not_matches 'existing [0-9]+'
  assert_failure

  run echo "some existing 42 text"
  run assert_output_not_matches 'EXISTING [0-9]+'
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

# Each negative case re-captures: a plain 'run' clears 'stderr', so a case that
# reused an earlier capture would only ever reach the guard.
@test "assert_stderr" {
  run --separate-stderr bash -c 'echo "some output"; echo "some error" >&2'
  assert_stderr "some error"
  assert_output "some output"

  run --separate-stderr bash -c 'echo "some error" >&2'
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
  assert_stderr_contains --case-sensitive "some existing error"

  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  assert_stderr_contains --regex 'existing [0-9]+'
  assert_stderr_contains --format "existing %d error"

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_contains "non-existing"
  assert_failure

  run --separate-stderr bash -c 'echo "some EXISTING error" >&2'
  run assert_stderr_contains --case-sensitive "some existing error"
  assert_failure

  unset stderr
  run assert_stderr_contains "existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_contains" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_contains "non-existing"

  run --separate-stderr bash -c 'echo "some EXISTING error" >&2'
  assert_stderr_not_contains --case-sensitive "some existing error"

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_not_contains "some existing error"
  assert_failure

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_not_contains "some EXISTING error"
  assert_failure

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_not_contains "existing"
  assert_failure

  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  run assert_stderr_not_contains --regex 'existing [0-9]+'
  assert_failure

  unset stderr
  run assert_stderr_not_contains "non-existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_matches" {
  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  assert_stderr_matches 'existing [0-9]+'
  assert_stderr_matches 'EXISTING [0-9]+'
  assert_stderr_matches '^some'
  assert_stderr_matches 'error$'
  assert_stderr_matches --case-sensitive 'existing [0-9]+'

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_matches 'existing [0-9]+'
  assert_failure

  run --separate-stderr bash -c 'echo "some EXISTING 42 error" >&2'
  run assert_stderr_matches --case-sensitive 'existing [0-9]+'
  assert_failure

  unset stderr
  run assert_stderr_matches 'existing'
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_matches" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_matches 'existing [0-9]+'

  run --separate-stderr bash -c 'echo "some EXISTING 42 error" >&2'
  assert_stderr_not_matches --case-sensitive 'existing [0-9]+'

  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  run assert_stderr_not_matches 'existing [0-9]+'
  assert_failure

  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  run assert_stderr_not_matches 'EXISTING [0-9]+'
  assert_failure

  unset stderr
  run assert_stderr_not_matches 'existing'
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
