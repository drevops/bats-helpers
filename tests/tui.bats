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
    "nothing"
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "Static script output"
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
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "SCRIPT_FILE is not set."
}

@test "Missing SCRIPT_FILE - caller recovers" {
  unset SCRIPT_FILE

  declare -a answers=(
    "nothing"
    "custom answer2"
  )

  recovered=0
  tui_run "${answers[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Non-existing SCRIPT_FILE" {
  export SCRIPT_FILE="tests/fixtures/tui_script_nonexisting.sh"

  declare -a answers=(
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "Script file 'tests/fixtures/tui_script_nonexisting.sh' does not exist."
}

@test "SCRIPT_FILE is not a regular file" {
  export SCRIPT_FILE="tests/fixtures"

  declare -a answers=(
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "Script file 'tests/fixtures' is not a regular file."
}

@test "Non-existing SCRIPT_FILE - caller recovers" {
  export SCRIPT_FILE="tests/fixtures/tui_script_nonexisting.sh"

  declare -a answers=(
    "nothing"
    "custom answer2"
  )

  recovered=0
  tui_run "${answers[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}
