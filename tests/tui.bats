#!/usr/bin/env bats
#
# Tests for TUI helpers.
#
# shellcheck disable=SC2030,SC2031

load _test_helper

@test "Interactive" {
  export BATS_HELPERS_SCRIPT_FILE="tests/fixtures/tui_script.sh"

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
  export BATS_HELPERS_SCRIPT_FILE="tests/fixtures/tui_script.sh"

  declare -a answers=(
    "nothing"
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "Static script output"
  assert_output_contains "default answer1"
  assert_output_contains "custom answer2"
}

@test "Missing BATS_HELPERS_SCRIPT_FILE" {
  unset BATS_HELPERS_SCRIPT_FILE
  unset SCRIPT_FILE

  declare -a answers=(
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "BATS_HELPERS_SCRIPT_FILE is not set."
}

@test "Missing BATS_HELPERS_SCRIPT_FILE - caller recovers" {
  unset BATS_HELPERS_SCRIPT_FILE
  unset SCRIPT_FILE

  declare -a answers=(
    "nothing"
    "custom answer2"
  )

  recovered=0
  tui_run "${answers[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Non-existing BATS_HELPERS_SCRIPT_FILE" {
  export BATS_HELPERS_SCRIPT_FILE="tests/fixtures/tui_script_nonexisting.sh"

  declare -a answers=(
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "BATS_HELPERS_SCRIPT_FILE does not exist."
}

@test "Non-existing BATS_HELPERS_SCRIPT_FILE - caller recovers" {
  export BATS_HELPERS_SCRIPT_FILE="tests/fixtures/tui_script_nonexisting.sh"

  declare -a answers=(
    "nothing"
    "custom answer2"
  )

  recovered=0
  tui_run "${answers[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}
