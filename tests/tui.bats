#!/usr/bin/env bats
#
# BATS tests for TUI helpers.
#
# shellcheck disable=SC2030,SC2031

load _test_helper

@test "Interactive" {
  export SCRIPT_FILE="tests/fixtures/fixture_tui.sh"

  answers=(
    "custom answer1"
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "Static script output"
  assert_output_contains "custom answer1"
  assert_output_contains "custom answer2"
}

@test "Defaults" {
  export SCRIPT_FILE="tests/fixtures/fixture_tui.sh"

  answers=(
    "nothing"
    "custom answer2"
  )
  tui_run "${answers[@]}"

  assert_output_contains "Static script output"
  assert_output_contains "default answer1"
  assert_output_contains "custom answer2"
}

@test "Missing SCRIPT_FILE" {
  answers=(
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "SCRIPT_FILE is not set."
}

@test "Non-existing SCRIPT_FILE" {
  export SCRIPT_FILE="tests/fixtures/fixture_tui_nonexisting.sh"

  answers=(
    "nothing"
    "custom answer2"
  )
  run tui_run "${answers[@]}"
  assert_failure
  assert_output_contains "SCRIPT_FILE does not exist."
}
