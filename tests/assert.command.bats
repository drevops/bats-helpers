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
  assert_output_contains "some EXISTING text"
  assert_output_contains "existing"
  assert_output_contains <<<"existing"

  run assert_output_contains "non-existing"
  assert_failure
}

@test "assert_output_contains_case" {
  run echo "some existing text"
  assert_output_contains_case "some existing text"
  assert_output_contains_case <<<"existing"

  run echo "some existing text"
  run assert_output_contains_case "some EXISTING text"
  assert_failure

  run assert_output_contains_case "non-existing"
  assert_failure
}

@test "assert_output_not_contains" {
  run echo "some existing text"
  assert_output_not_contains "non-existing"
  assert_output_not_contains <<<"non-existing"

  run assert_output_not_contains "some existing text"
  assert_failure

  run assert_output_not_contains "some EXISTING text"
  assert_failure

  run assert_output_not_contains "existing"
  assert_failure
}

@test "assert_output_not_contains_case" {
  run echo "some existing text"
  assert_output_not_contains_case "non-existing"
  assert_output_not_contains_case "some EXISTING text"

  run echo "some existing text"
  run assert_output_not_contains_case "some existing text"
  assert_failure
}

@test "assert_output_matches" {
  run echo "some existing 42 text"
  assert_output_matches 'existing [0-9]+'
  assert_output_matches 'EXISTING [0-9]+'
  assert_output_matches '^some'
  assert_output_matches 'text$'
  assert_output_matches <<<'existing [0-9]+'

  run echo "some existing text"
  run assert_output_matches 'existing [0-9]+'
  assert_failure
}

@test "assert_output_matches_case" {
  run echo "some existing 42 text"
  assert_output_matches_case 'existing [0-9]+'

  run echo "some EXISTING 42 text"
  run assert_output_matches_case 'existing [0-9]+'
  assert_failure

  run echo "some existing text"
  run assert_output_matches_case 'existing [0-9]+'
  assert_failure
}

@test "assert_output_not_matches" {
  run echo "some existing text"
  assert_output_not_matches 'existing [0-9]+'

  run echo "some existing 42 text"
  run assert_output_not_matches 'existing [0-9]+'
  assert_failure

  run echo "some existing 42 text"
  run assert_output_not_matches 'EXISTING [0-9]+'
  assert_failure
}

@test "assert_output_not_matches_case" {
  run echo "some existing text"
  assert_output_not_matches_case 'existing [0-9]+'

  run echo "some EXISTING 42 text"
  assert_output_not_matches_case 'existing [0-9]+'

  run echo "some existing 42 text"
  run assert_output_not_matches_case 'existing [0-9]+'
  assert_failure
}

@test "assert_output_matches_format" {
  run echo "Deleted 12 files in 0.5s"
  assert_output_matches_format "Deleted %d files in %fs"
  assert_output_matches_format "DELETED %d files"
  assert_output_matches_format <<<"Deleted %d files"

  run echo "Deleted some files"
  run assert_output_matches_format "Deleted %d files"
  assert_failure
}

@test "assert_output_matches_format_case" {
  run echo "Deleted 12 files"
  assert_output_matches_format_case "Deleted %d files"

  run echo "DELETED 12 files"
  run assert_output_matches_format_case "Deleted %d files"
  assert_failure
}

@test "assert_output_not_matches_format" {
  run echo "Deleted some files"
  assert_output_not_matches_format "Deleted %d files"

  run echo "Deleted 12 files"
  run assert_output_not_matches_format "Deleted %d files"
  assert_failure

  run echo "DELETED 12 files"
  run assert_output_not_matches_format "Deleted %d files"
  assert_failure
}

@test "assert_output_not_matches_format_case" {
  run echo "Deleted some files"
  assert_output_not_matches_format_case "Deleted %d files"

  run echo "DELETED 12 files"
  assert_output_not_matches_format_case "Deleted %d files"

  run echo "Deleted 12 files"
  run assert_output_not_matches_format_case "Deleted %d files"
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
  assert_stderr_contains <<<"existing"

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_contains "non-existing"
  assert_failure

  unset stderr
  run assert_stderr_contains "existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_contains_case" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_contains_case "some existing error"

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_contains_case "some EXISTING error"
  assert_failure

  unset stderr
  run assert_stderr_contains_case "existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_contains" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_contains "non-existing"

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_not_contains "some existing error"
  assert_failure

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_not_contains "some EXISTING error"
  assert_failure

  unset stderr
  run assert_stderr_not_contains "non-existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_contains_case" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_contains_case "non-existing"
  assert_stderr_not_contains_case "some EXISTING error"

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_not_contains_case "some existing error"
  assert_failure

  unset stderr
  run assert_stderr_not_contains_case "non-existing"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_matches" {
  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  assert_stderr_matches 'existing [0-9]+'
  assert_stderr_matches 'EXISTING [0-9]+'
  assert_stderr_matches '^some'
  assert_stderr_matches 'error$'

  run --separate-stderr bash -c 'echo "some existing error" >&2'
  run assert_stderr_matches 'existing [0-9]+'
  assert_failure

  unset stderr
  run assert_stderr_matches 'existing'
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_matches_case" {
  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  assert_stderr_matches_case 'existing [0-9]+'

  run --separate-stderr bash -c 'echo "some EXISTING 42 error" >&2'
  run assert_stderr_matches_case 'existing [0-9]+'
  assert_failure

  unset stderr
  run assert_stderr_matches_case 'existing'
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_matches" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_matches 'existing [0-9]+'

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

@test "assert_stderr_not_matches_case" {
  run --separate-stderr bash -c 'echo "some existing error" >&2'
  assert_stderr_not_matches_case 'existing [0-9]+'

  run --separate-stderr bash -c 'echo "some EXISTING 42 error" >&2'
  assert_stderr_not_matches_case 'existing [0-9]+'

  run --separate-stderr bash -c 'echo "some existing 42 error" >&2'
  run assert_stderr_not_matches_case 'existing [0-9]+'
  assert_failure

  unset stderr
  run assert_stderr_not_matches_case 'existing'
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_matches_format" {
  run --separate-stderr bash -c 'echo "Deleted 12 files in 0.5s" >&2'
  assert_stderr_matches_format "Deleted %d files in %fs"
  assert_stderr_matches_format "DELETED %d files"

  run --separate-stderr bash -c 'echo "Deleted some files" >&2'
  run assert_stderr_matches_format "Deleted %d files"
  assert_failure

  unset stderr
  run assert_stderr_matches_format "Deleted %d files"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_matches_format_case" {
  run --separate-stderr bash -c 'echo "Deleted 12 files" >&2'
  assert_stderr_matches_format_case "Deleted %d files"

  run --separate-stderr bash -c 'echo "DELETED 12 files" >&2'
  run assert_stderr_matches_format_case "Deleted %d files"
  assert_failure

  unset stderr
  run assert_stderr_matches_format_case "Deleted %d files"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_matches_format" {
  run --separate-stderr bash -c 'echo "Deleted some files" >&2'
  assert_stderr_not_matches_format "Deleted %d files"

  run --separate-stderr bash -c 'echo "Deleted 12 files" >&2'
  run assert_stderr_not_matches_format "Deleted %d files"
  assert_failure

  unset stderr
  run assert_stderr_not_matches_format "Deleted %d files"
  assert_failure
  assert_output_contains "run --separate-stderr"
}

@test "assert_stderr_not_matches_format_case" {
  run --separate-stderr bash -c 'echo "DELETED 12 files" >&2'
  assert_stderr_not_matches_format_case "Deleted %d files"

  run --separate-stderr bash -c 'echo "Deleted 12 files" >&2'
  run assert_stderr_not_matches_format_case "Deleted %d files"
  assert_failure

  unset stderr
  run assert_stderr_not_matches_format_case "Deleted %d files"
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

@test "command_assert_match" {
  # The first 'run' supplies the output the assertion reads, before the second
  # replaces it with the failure report.
  run echo "some existing text"
  run assert_output_contains "some" "extra"
  assert_failure
  assert_output_contains "A needle is required."
}
