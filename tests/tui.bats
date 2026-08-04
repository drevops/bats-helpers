#!/usr/bin/env bats
#
# Tests for TUI helpers.
#
# shellcheck disable=SC2030,SC2031

load _test_helper

@test "Interactive" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  declare -a answers=(
    "custom answer1"
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "Static script output"
  assert_output_contains "custom answer1"
  assert_output_contains "custom answer2"
}

@test "Defaults" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  declare -a answers=(
    ""
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "Static script output"
  assert_output_contains "default answer1"
  assert_output_contains "custom answer2"
}

@test "Deprecated 'nothing' answer submits a blank line" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"
  export BATS_HELPERS_DEPRECATION_QUIET=1

  declare -a answers=(
    "nothing"
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "default answer1"
  assert_output_contains "custom answer2"
}

@test "Answers reach the script literally" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  declare -a answers=(
    "it's a quoted answer"
    "100% of %s answers"
  )
  tui_run "${answers[@]}"

  assert_output_contains "it's a quoted answer"
  assert_output_contains "100% of %s answers"
}

@test "Answers containing backslash escapes are not decoded" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  declare -a answers=(
    'literal\nnewline'
    'literal\ctruncate'
  )
  tui_run "${answers[@]}"

  assert_output_contains 'literal\nnewline'
  assert_output_contains 'literal\ctruncate'
}

@test "Answer count is published" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  tui_run "custom answer1" "custom answer2"

  assert_equal 2 "${BATS_HELPERS_TUI_ANSWERS}"
}

@test "Absolute script path containing a space" {
  cp "${BATS_TEST_DIRNAME}/fixtures/tui_script.sh" "${BATS_TEST_TMPDIR}/tui script.sh"
  export SCRIPT_FILE="${BATS_TEST_TMPDIR}/tui script.sh"

  tui_run "custom answer1" "custom answer2"

  assert_output_contains "Static script output"
  assert_output_contains "custom answer1"
}

@test "Script path containing a space" {
  cp "${BATS_TEST_DIRNAME}/fixtures/tui_script.sh" "${BATS_TEST_TMPDIR}/tui script.sh"
  export SCRIPT_FILE="tui script.sh"
  pushd "${BATS_TEST_TMPDIR}"

  tui_run "custom answer1" "custom answer2"

  assert_output_contains "Static script output"
  assert_output_contains "custom answer1"

  popd
}

@test "Missing SCRIPT_FILE" {
  unset SCRIPT_FILE

  declare -a answers=(
    ""
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "SCRIPT_FILE is not set."
}

@test "Missing SCRIPT_FILE - caller recovers" {
  unset SCRIPT_FILE

  declare -a answers=(
    ""
    "custom answer2"
  )

  recovered=0
  tui_run "${answers[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Non-existing SCRIPT_FILE" {
  export SCRIPT_FILE="tests/fixtures/tui_script_nonexisting.sh"

  declare -a answers=(
    ""
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "Script file 'tests/fixtures/tui_script_nonexisting.sh' does not exist."
}

@test "SCRIPT_FILE is not a regular file" {
  export SCRIPT_FILE="tests/fixtures"

  declare -a answers=(
    ""
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "Script file 'tests/fixtures' is not a regular file."
}

@test "Non-existing SCRIPT_FILE - caller recovers" {
  export SCRIPT_FILE="tests/fixtures/tui_script_nonexisting.sh"

  declare -a answers=(
    ""
    "custom answer2"
  )

  recovered=0
  tui_run "${answers[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Sandbox cannot be resolved" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"
  sandbox="${BATS_TEST_TMPDIR}"
  BATS_TEST_TMPDIR=""

  run tui_run "custom answer1" "custom answer2"

  BATS_TEST_TMPDIR="${sandbox}"

  assert_failure
  assert_output_contains "TUI sandbox cannot be resolved: 'BATS_TEST_TMPDIR' is not set."
}

##
## Deadline.
##

@test "Script that prompts more times than it has answers" {
  export SCRIPT_FILE="tests/fixtures/tui_script_prompts.sh"
  export BATS_HELPERS_TUI_TIMEOUT=2

  run tui_run "one"

  assert_failure
  assert_output_contains "Script 'tests/fixtures/tui_script_prompts.sh' did not finish within the 2 second timeout"
  assert_output_matches_format "elapsed: %d second(s)"
  assert_output_contains "Static script output"
  assert_output_contains "Answer2 [default answer2]:"
}

@test "Deadline is configurable" {
  export SCRIPT_FILE="tests/fixtures/tui_script_prompts.sh"
  export BATS_HELPERS_TUI_TIMEOUT=30

  tui_run "one" "two"

  assert_output_contains "one"
  assert_output_contains "two"
}

@test "Deadline is not a whole number of seconds" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"
  export BATS_HELPERS_TUI_TIMEOUT="1.5"

  run tui_run "custom answer1" "custom answer2"

  assert_failure
  assert_output_contains "Timeout '1.5' is not a whole number of seconds."
}

@test "Deadline is not greater than zero" {
  export SCRIPT_FILE="tests/fixtures/tui_script.sh"

  export BATS_HELPERS_TUI_TIMEOUT=0
  run tui_run "custom answer1" "custom answer2"
  assert_failure
  assert_output_contains "Timeout must be greater than zero."

  export BATS_HELPERS_TUI_TIMEOUT=-1
  run tui_run "custom answer1" "custom answer2"
  assert_failure
  assert_output_contains "Timeout must be greater than zero."
}

##
## Prompt assertions.
##

@test "tui_assert_prompts" {
  export SCRIPT_FILE="tests/fixtures/tui_script_prompts.sh"

  tui_run "one" "two"
  tui_assert_prompts "Answer1" "Answer2"

  tui_run "one" "two"
  tui_assert_prompts "ANSWER1" "ANSWER2"

  tui_run "one" "two"
  run tui_assert_prompts "Answer1" "Answer3"
  assert_failure
  assert_output_contains "Prompt 'Answer3' does not appear in the remaining output"
  assert_output_contains "matched: 1 of 2"

  tui_run "one" "two"
  run tui_assert_prompts "Answer2" "Answer1"
  assert_failure
  assert_output_contains "Prompt 'Answer1' does not appear in the remaining output"
  assert_output_contains "matched: 1 of 2"
}

@test "tui_assert_prompts_case" {
  export SCRIPT_FILE="tests/fixtures/tui_script_prompts.sh"

  tui_run "one" "two"
  tui_assert_prompts_case "Answer1" "Answer2"

  tui_run "one" "two"
  run tui_assert_prompts_case "ANSWER1" "ANSWER2"
  assert_failure
  assert_output_contains "Prompt 'ANSWER1' does not appear in the remaining output"
  assert_output_contains "matched: 0 of 2"
}

@test "Answer count does not match the prompt count" {
  export SCRIPT_FILE="tests/fixtures/tui_script_prompts.sh"

  tui_run "one" "two"
  run tui_assert_prompts "Answer1"
  assert_failure
  assert_output_contains "Script was answered 2 time(s), but 1 prompt(s) are expected"

  tui_run "one" "two"
  run tui_assert_prompts "Answer1" "Answer2" "Answer3"
  assert_failure
  assert_output_contains "Script was answered 2 time(s), but 3 prompt(s) are expected"
}

@test "Script that prompts for nothing" {
  export SCRIPT_FILE="tests/fixtures/tui_script_silent.sh"

  tui_run
  assert_output_contains "Static script output"
  tui_assert_prompts

  tui_run
  run tui_assert_prompts "Answer1"
  assert_failure
  assert_output_contains "Script was answered 0 time(s), but 1 prompt(s) are expected"
}

@test "Prompts asserted before a script has run" {
  unset BATS_HELPERS_TUI_ANSWERS

  run tui_assert_prompts "Answer1"

  assert_failure
  assert_output_contains "No script has been run. Run 'tui_run' first."
}

@test "Empty prompt" {
  export SCRIPT_FILE="tests/fixtures/tui_script_prompts.sh"

  tui_run "one" "two"

  run tui_assert_prompts "Answer1" ""

  assert_failure
  assert_output_contains "Prompt must not be empty."
}

@test "Missing case sensitivity flag" {
  run tui_prompts_assert_match

  assert_failure
  assert_output_contains "A case sensitivity flag is required."
}
