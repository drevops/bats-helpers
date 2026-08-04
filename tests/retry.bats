#!/usr/bin/env bats
#
# Tests for the retry helper.
#
# shellcheck disable=SC2030,SC2031

load _test_helper

##
# Succeeds on the call named by the threshold, and fails before it.
#
# The count is kept in a file because every attempt runs in its own subshell.
#
# Arguments:
#   1. threshold: Call the probe starts succeeding on.
#
# Globals:
#   BATS_TEST_TMPDIR: Directory holding the counter.
#
# Outputs:
#   STDOUT: The number of the call.
##
fixture_probe() {
  local threshold="${1}"
  local counter="${BATS_TEST_TMPDIR}/probe.count"

  local count=0

  if [ -f "${counter}" ]; then
    count="$(cat "${counter}")"
  fi

  count=$((count + 1))
  echo -n "${count}" >"${counter}"

  echo "probed ${count}"

  [ "${count}" -ge "${threshold}" ]
}

##
# Prints every argument it receives, one per line and delimited.
#
# Arguments:
#   1+. args: Arguments to print. Optional.
#
# Outputs:
#   STDOUT: One delimited argument per line.
##
fixture_echo_args() {
  printf '[%s]\n' "$@"
}

##
# Asserts that a whole number of seconds falls within a range.
#
# Arguments:
#   1. elapsed: Seconds measured.
#   2. min: Lowest acceptable value.
#   3. max: Highest acceptable value.
##
fixture_assert_elapsed() {
  local elapsed="${1}"
  local min="${2}"
  local max="${3}"

  if [ "${elapsed}" -lt "${min}" ] || [ "${elapsed}" -gt "${max}" ]; then
    flunk "Elapsed time ${elapsed} is outside the expected range of ${min} to ${max} seconds."
  fi
}

@test "retry_run" {
  retry_run 3 5 true

  assert_equal 1 "${BATS_HELPERS_RETRY_ATTEMPTS}"
  assert_equal "" "${BATS_HELPERS_RETRY_OUTPUT}"
  fixture_assert_elapsed "${BATS_HELPERS_RETRY_ELAPSED}" 0 1

  run retry_run 3 0 false
  assert_failure
}

@test "retry_run with a condition that becomes true" {
  local mock_sleep
  mock_sleep="$(mock_command "sleep")"

  retry_run 5 0.1 fixture_probe 3

  assert_equal 3 "${BATS_HELPERS_RETRY_ATTEMPTS}"
  assert_equal "probed 3" "${BATS_HELPERS_RETRY_OUTPUT}"
  assert_equal 2 "$(mock_get_call_num "${mock_sleep}")"
}

@test "retry_run with an exhausted attempt count" {
  local mock_sleep
  mock_sleep="$(mock_command "sleep")"

  run retry_run 3 0.1 fixture_probe 99
  assert_failure
  assert_output_contains "Command 'fixture_probe' did not succeed within 3 attempt(s)"
  assert_output_contains "attempts: 3"
  assert_output_matches_format "elapsed: %d second(s)"
  assert_output_contains "last status: 1"
  assert_output_contains "last output: 'probed 3'"

  assert_equal 3 "$(cat "${BATS_TEST_TMPDIR}/probe.count")"
  assert_equal 2 "$(mock_get_call_num "${mock_sleep}")"
}

@test "retry_run sleeps between attempts only" {
  local mock_sleep
  mock_sleep="$(mock_command "sleep")"

  run retry_run 3 0.25 false
  assert_failure

  assert_equal 2 "$(mock_get_call_num "${mock_sleep}")"
  mock_assert_call_args "${mock_sleep}" "0.25" 1
  mock_assert_call_args "${mock_sleep}" "0.25" 2
}

# The delay is large enough that a wait taken before the first attempt would
# show up in the elapsed time.
@test "retry_run does not delay before the first attempt" {
  local start="${SECONDS}"

  retry_run 3 5 true

  fixture_assert_elapsed "$((SECONDS - start))" 0 1
}

# The only attempt is also the last one, so any wait taken after an attempt
# would show up in the elapsed time.
@test "retry_run does not delay after the last attempt" {
  local start="${SECONDS}"

  run retry_run 1 5 false
  assert_failure
  assert_output_contains "did not succeed within 1 attempt(s)"

  fixture_assert_elapsed "$((SECONDS - start))" 0 1
}

@test "retry_run with a fractional delay" {
  local mock_sleep
  mock_sleep="$(mock_command "sleep")"

  run retry_run 2 ".5" false
  assert_failure

  mock_assert_call_args "${mock_sleep}" ".5" 1
}

@test "retry_run with a deadline of zero" {
  mock_command "sleep" >/dev/null

  export BATS_HELPERS_RETRY_TIMEOUT=0

  run retry_run 5 1 false
  assert_failure
  assert_output_contains "Command 'false' did not succeed within the 0 second deadline"
  assert_output_contains "attempts: 1"

  mock_assert_not_called "sleep"
}

# The one test that lets the clock run, because a mocked 'sleep' leaves the
# elapsed time at zero and no deadline is ever reached.
@test "retry_run with a deadline that is reached" {
  export BATS_HELPERS_RETRY_TIMEOUT=1

  local start="${SECONDS}"

  run retry_run 10 1 false
  assert_failure
  assert_output_contains "Command 'false' did not succeed within the 1 second deadline"
  assert_output_matches "attempts: [12]"

  # The attempt count alone would have taken nine seconds.
  fixture_assert_elapsed "$((SECONDS - start))" 0 3
}

@test "retry_run with a deadline that is not reached" {
  local mock_sleep
  mock_sleep="$(mock_command "sleep")"

  export BATS_HELPERS_RETRY_TIMEOUT=60

  run retry_run 3 0.1 false
  assert_failure
  assert_output_contains "did not succeed within 3 attempt(s)"

  assert_equal 2 "$(mock_get_call_num "${mock_sleep}")"
}

@test "retry_run with an empty deadline" {
  export BATS_HELPERS_RETRY_TIMEOUT=""

  retry_run 3 0.1 true

  assert_equal 1 "${BATS_HELPERS_RETRY_ATTEMPTS}"
}

@test "retry_run with a library assertion" {
  local file="${BATS_TEST_TMPDIR}/late.txt"

  local mock_sleep
  mock_sleep="$(mock_command "sleep")"
  mock_set_status "${mock_sleep}" 0
  mock_set_side_effect "${mock_sleep}" "touch '${file}'" 2

  assert_file_not_exists "${file}"

  retry_run 5 0.1 assert_file_exists "${file}"

  assert_equal 3 "${BATS_HELPERS_RETRY_ATTEMPTS}"
  assert_file_exists "${file}"

  run retry_run 2 0.1 assert_file_not_exists "${file}"
  assert_failure
  assert_output_contains "File '\${BATS_TEST_TMPDIR}/late.txt' exists, but should not"
}

@test "retry_run passes arguments verbatim" {
  retry_run 1 0 fixture_echo_args "with space" "" "hash#" "quote'd"

  assert_equal "[with space]
[]
[hash#]
[quote'd]" "${BATS_HELPERS_RETRY_OUTPUT}"
}

@test "retry_run resets its result globals" {
  mock_command "sleep" >/dev/null

  retry_run 5 0.1 fixture_probe 3
  assert_equal 3 "${BATS_HELPERS_RETRY_ATTEMPTS}"
  assert_equal "probed 3" "${BATS_HELPERS_RETRY_OUTPUT}"

  retry_run 5 0.1 true
  assert_equal 1 "${BATS_HELPERS_RETRY_ATTEMPTS}"
  assert_equal "" "${BATS_HELPERS_RETRY_OUTPUT}"
}

@test "retry_run reports the attempt it succeeded on" {
  local notice="${BATS_TEST_TMPDIR}/notice.txt"

  mock_command "sleep" >/dev/null

  retry_run 5 0.1 fixture_probe 3 3>"${notice}"

  assert_file_matches_format "${notice}" "Retried: 'fixture_probe' succeeded on attempt 3 of 5 after %d seconds."

  # An immediate success is the common case and stays silent.
  retry_run 5 0.1 true 3>"${notice}"

  assert_equal "" "$(cat "${notice}")"
}

@test "retry_run without enough arguments" {
  run retry_run
  assert_failure
  assert_output_contains "An attempt count, a delay and a command are required."

  run retry_run 3
  assert_failure
  assert_output_contains "An attempt count, a delay and a command are required."

  run retry_run 3 0.1
  assert_failure
  assert_output_contains "An attempt count, a delay and a command are required."
}

@test "retry_run with an invalid attempt count" {
  run retry_run "abc" 0.1 true
  assert_failure
  assert_output_contains "Attempt count 'abc' is not an integer."

  run retry_run "2.5" 0.1 true
  assert_failure
  assert_output_contains "Attempt count '2.5' is not an integer."

  run retry_run "" 0.1 true
  assert_failure
  assert_output_contains "Attempt count '' is not an integer."

  run retry_run 0 0.1 true
  assert_failure
  assert_output_contains "Attempt count must be greater than zero."

  run retry_run -2 0.1 true
  assert_failure
  assert_output_contains "Attempt count must be greater than zero."
}

@test "retry_run with an invalid delay" {
  run retry_run 3 "abc" true
  assert_failure
  assert_output_contains "Delay 'abc' is not a non-negative number."

  run retry_run 3 "-1" true
  assert_failure
  assert_output_contains "Delay '-1' is not a non-negative number."

  run retry_run 3 "1." true
  assert_failure
  assert_output_contains "Delay '1.' is not a non-negative number."

  run retry_run 3 "" true
  assert_failure
  assert_output_contains "Delay '' is not a non-negative number."
}

@test "retry_run with an invalid command" {
  run retry_run 3 0.1 ""
  assert_failure
  assert_output_contains "Command name must not be empty."

  run retry_run 3 0.1 "bats_helpers_no_such_command"
  assert_failure
  assert_output_contains "Command 'bats_helpers_no_such_command' is not a valid command."
}

@test "retry_run with an invalid deadline" {
  export BATS_HELPERS_RETRY_TIMEOUT="abc"

  run retry_run 3 0.1 true
  assert_failure
  assert_output_contains "Deadline 'abc' is not a whole number of seconds."

  export BATS_HELPERS_RETRY_TIMEOUT="1.5"

  run retry_run 3 0.1 true
  assert_failure
  assert_output_contains "Deadline '1.5' is not a whole number of seconds."

  export BATS_HELPERS_RETRY_TIMEOUT="-1"

  run retry_run 3 0.1 true
  assert_failure
  assert_output_contains "Deadline '-1' is not a whole number of seconds."
}
