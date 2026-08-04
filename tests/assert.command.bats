#!/usr/bin/env bats
#
# Tests for command assertions.
#
# shellcheck disable=SC2129

load _test_helper

# Matches the library's minimum, and silences the warning flags on 'run' emit.
bats_require_minimum_version 1.13.0

# A report carries the captured output, so each case clears the capture the
# previous 'run' left behind. Without that, an assertion below could be
# satisfied by the text of an earlier failure rather than by the one it names.
@test "assert_success" {
  status=0
  assert_success

  output=""
  status=1
  run assert_success
  [ "${status}" -eq 1 ]
  assert_output_contains "-- Command failed --"
  assert_output_contains "status : 1"
  assert_output_not_contains "output :"
  assert_output_not_contains "stderr :"

  output=""
  status=127
  run assert_success
  [ "${status}" -eq 1 ]
  assert_output_contains "status : 127 (command not found)"

  output=""
  status=137
  run assert_success
  [ "${status}" -eq 1 ]
  assert_output_contains "status : 137 (killed by SIGKILL)"

  output="captured output"
  stderr="stderr needle"
  status=1
  run assert_success
  [ "${status}" -eq 1 ]
  assert_output_contains "output : captured output"
  assert_output_contains "stderr : stderr needle"
}

@test "assert_failure" {
  status=1
  assert_failure

  output=""
  unset stderr
  status=0
  run assert_failure
  [ "${status}" -eq 1 ]
  assert_output_contains "-- Command succeeded, but should have failed --"
  assert_output_not_contains "output :"
  assert_output_not_contains "stderr :"

  output=""
  stderr="stderr needle"
  status=0
  run assert_failure
  [ "${status}" -eq 1 ]
  assert_output_contains "stderr : stderr needle"

  status=2
  assert_failure --status 2

  output="some output"
  status=2
  assert_failure --status 2 "some output"

  output=""
  status=2
  run assert_failure --status 3
  assert_failure
  assert_output_contains "expected : 3"
  assert_output_contains "actual   : 2"

  status=2
  run assert_failure --status
  assert_failure
  assert_output_contains "Option '--status' requires an exit status."

  status=2
  run assert_failure --status 0
  assert_failure
  assert_output_contains "A failure cannot have exit status 0. Use 'assert_success' instead."

  # The command succeeded, so only validating the option first surfaces the
  # malformed value rather than the failure that did not happen.
  status=0
  run assert_failure --status two
  assert_failure
  assert_output_contains "Exit status 'two' is not an integer between 0 and 255."
}

@test "assert_status" {
  status=0
  assert_status 0

  status=2
  assert_status 2

  # A real signal death, so that the 128 offset is asserted end to end and not
  # only against a status the test wrote itself.
  run bash -c 'kill -KILL $$'
  assert_status 137

  output=""
  status=2
  run assert_status 3
  assert_failure
  assert_output_contains "-- Command exited with an unexpected status --"
  assert_output_contains "expected : 3"
  assert_output_contains "actual   : 2"

  output=""
  status=127
  run assert_status 2
  assert_failure
  assert_output_contains "actual   : 127 (command not found)"

  output=""
  status=137
  run assert_status 2
  assert_failure
  assert_output_contains "actual   : 137 (killed by SIGKILL)"

  status=2
  run assert_status
  assert_failure
  assert_output_contains "An expected exit status is required."

  status=2
  run assert_status two
  assert_failure
  assert_output_contains "Exit status 'two' is not an integer between 0 and 255."

  status=2
  run assert_status 256
  assert_failure
  assert_output_contains "Exit status '256' is not an integer between 0 and 255."
}

@test "assert_status_general_error" {
  status=1
  assert_status_general_error

  status=2
  run assert_status_general_error
  assert_failure
  assert_output_contains "expected : 1"
  assert_output_contains "actual   : 2"
}

@test "assert_status_command_not_found" {
  # The status is asserted by 'run' as well, so the case proves that a missing
  # command is 127 on this platform before the library is asked about it.
  run -127 this-command-does-not-exist
  assert_status_command_not_found

  status=1
  run assert_status_command_not_found
  assert_failure
  assert_output_contains "expected : 127"
  assert_output_contains "actual   : 1"
}

@test "command_describe_status" {
  run command_describe_status 0
  assert_success
  assert_output "0"

  run command_describe_status 3
  assert_success
  assert_output "3"

  run command_describe_status 127
  assert_success
  assert_output "127 (command not found)"

  # Only the two signals every supported platform numbers the same way.
  run command_describe_status 137
  assert_success
  assert_output "137 (killed by SIGKILL)"

  run command_describe_status 143
  assert_success
  assert_output "143 (killed by SIGTERM)"

  # The offset leaves signal zero, which is not a signal.
  run command_describe_status 128
  assert_success
  assert_output "128"

  # No supported platform numbers a signal this high.
  run command_describe_status 255
  assert_success
  assert_output "255"
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

  run echo "some existing text"
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
