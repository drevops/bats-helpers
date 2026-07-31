#!/usr/bin/env bats
#
# Tests for base assertion helpers.
#
# shellcheck disable=SC2129,SC2016

load _test_helper

@test "bats_internals" {
  echo "Bats version ${BATS_VERSION}" >&3
  [ "${BATS_FILE_TMPDIR}" != "" ]
  [ "${BATS_TEST_TMPDIR}" != "" ]
  [ "${BATS_SUITE_TMPDIR}" != "" ]
}

@test "flunk" {
  run flunk "Some message"
  assert_failure
  assert_output "Some message"

  run flunk <<<"Piped message"
  assert_failure
  assert_output "Piped message"

  # Single quotes keep the expectation literal: the temporary directory path is
  # rewritten to the variable name so failure output stays stable across runs.
  run flunk "Path ${BATS_TEST_TMPDIR}/some.txt"
  assert_failure
  assert_output 'Path ${BATS_TEST_TMPDIR}/some.txt'
}

@test "format_error" {
  # 'format_error' appends the captured output of the last 'run', so each case
  # sets it explicitly rather than inheriting it from an earlier assertion.
  output=""
  run format_error "Some message"
  assert_success
  assert_output_contains "BEGIN ERROR MESSAGE"
  assert_output_contains "Some message"
  assert_output_contains "END ERROR MESSAGE"
  assert_output_not_contains "----------------------------------------"

  output="Some captured output"
  run format_error "Some message"
  assert_success
  assert_output_contains "Some message"
  assert_output_contains "----------------------------------------"
  assert_output_contains "${BATS_TEST_TMPDIR}"
  assert_output_contains "Some captured output"
}
