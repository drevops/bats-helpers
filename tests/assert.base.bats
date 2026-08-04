#!/usr/bin/env bats
#
# Tests for failure reporting.
#
# shellcheck disable=SC2129,SC2016,SC2034

load _test_helper

##
# Consumer frames for the stack trace, wrapped twice so that the frame of the
# helper that called the assertion is reported and not only the call to 'run'.
##
report_trace_assert() {
  assert_file_exists "${BATS_TEST_TMPDIR}/non-existing"
}

report_trace_wrapper() {
  report_trace_assert
}

@test "bats_internals" {
  echo "Bats version ${BATS_VERSION}" >&3
  [ "${BATS_FILE_TMPDIR}" != "" ]
  [ "${BATS_TEST_TMPDIR}" != "" ]
  [ "${BATS_SUITE_TMPDIR}" != "" ]
}

@test "flunk" {
  run flunk "Some message"
  assert_failure
  assert_output_contains "Some message"

  run flunk <<<"Piped message"
  assert_failure
  assert_output_contains "Piped message"

  # Single quotes keep the expectation literal: the temporary directory path is
  # rewritten to the variable name so failure output stays stable across runs.
  run flunk "Path ${BATS_TEST_TMPDIR}/some.txt"
  assert_failure
  assert_output_contains 'Path ${BATS_TEST_TMPDIR}/some.txt'
}

@test "flunk appends the stack trace of the caller" {
  run report_trace_wrapper
  assert_failure
  assert_output_contains "-- stack trace --"

  # The frame of the assertion the helper called, and the frame of the helper
  # itself, both named against the file the consumer wrote.
  assert_output_contains ': assert_file_exists'
  assert_output_contains ': report_trace_assert'
  assert_output_contains '${PWD}/tests/assert.base.bats'

  # The library reaches its own report through several frames, none of which
  # tell the reader anything about their own code.
  assert_output_not_contains ": flunk"
  assert_output_not_contains ": format_error"
  assert_output_not_contains "bats-exec-test"
}

@test "format_error aligns single-line rows" {
  run format_error "String does not contain substring" "string" "some text" "substring" "SOME"
  assert_success
  assert_output "-- String does not contain substring --
string    : some text
substring : SOME
--"
}

@test "format_error renders a title on its own" {
  run format_error "Command succeeded, but should have failed"
  assert_success
  assert_output "-- Command succeeded, but should have failed --
--"
}

@test "format_error switches every row to the multi-line form together" {
  run format_error "Output has no line containing substring" "substring" "absent" "context" $'  0: first\n> 1: second'
  assert_success
  assert_output "-- Output has no line containing substring --
substring (1 line):
absent
context (2 lines):
  0: first
> 1: second
--"
}

@test "format_error diffs a multi-line expected and actual pair" {
  run format_error "Strings are not equal" "expected" $'first\nsecond\nthird' "actual" $'first\nchanged\nthird'
  assert_success
  assert_output "-- Strings are not equal --
--- expected
+++ actual
@@ -1,3 +1,3 @@
 first
-second
+changed
 third
--"
}

@test "format_error keeps the other rows beside a diff" {
  run format_error "Strings are not equal" "file" "some.txt" "expected" $'first\nsecond' "actual" $'first\nchanged'
  assert_success
  assert_output "-- Strings are not equal --
file (1 line):
some.txt
--- expected
+++ actual
@@ -1,2 +1,2 @@
 first
-second
+changed
--"
}

@test "format_error leaves a single-line expected and actual pair as rows" {
  run format_error "Command exited with an unexpected status" "expected" "3" "actual" "2"
  assert_success
  assert_output "-- Command exited with an unexpected status --
expected : 3
actual   : 2
--"

  # Another row spanning lines decides how the rows are laid out, not whether
  # the pair is worth diffing.
  run format_error "Command exited with an unexpected status" "expected" "3" "actual" "2" "output" $'first\nsecond'
  assert_success
  assert_output "-- Command exited with an unexpected status --
expected (1 line):
3
actual (1 line):
2
output (2 lines):
first
second
--"
}

@test "format_error rewrites the volatile paths" {
  run format_error "File does not exist" "file" "${BATS_TEST_TMPDIR}/some.txt"
  assert_success
  assert_output '-- File does not exist --
file : ${BATS_TEST_TMPDIR}/some.txt
--'
}

@test "format_error rejects a malformed call" {
  run format_error
  assert_failure
  assert_output_contains "A failure report requires a title."

  run format_error "Some title" "key"
  assert_failure
  assert_output_contains "Failure report rows require a key and a value each."
}

@test "A diff is coloured when the platform supports it" {
  if ! report_diff_color_supported; then
    skip "the platform's diff does not understand the colour flag"
  fi

  unset NO_COLOR
  BATS_HELPERS_REPORT_COLOR=1
  run format_error "Strings are not equal" "expected" $'first\nsecond' "actual" $'first\nchanged'
  assert_success
  assert_output_contains $'\033['

  BATS_HELPERS_REPORT_COLOR=0
  run format_error "Strings are not equal" "expected" $'first\nsecond' "actual" $'first\nchanged'
  assert_success
  assert_output_not_contains $'\033['
}

@test "report_decorate" {
  run report_decorate "Some title" "Some body"
  assert_success
  assert_output "-- Some title --
Some body
--"

  run report_decorate "Some title" ""
  assert_success
  assert_output "-- Some title --
--"
}

@test "report_count_lines" {
  run report_count_lines ""
  assert_success
  assert_output "1"

  run report_count_lines "one line"
  assert_success
  assert_output "1"

  run report_count_lines $'first\nsecond'
  assert_success
  assert_output "2"

  # A trailing newline closes one line and opens another.
  run report_count_lines $'first\n'
  assert_success
  assert_output "2"
}

@test "report_plural_lines" {
  run report_plural_lines 0
  assert_success
  assert_output "0 lines"

  run report_plural_lines 1
  assert_success
  assert_output "1 line"

  run report_plural_lines 2
  assert_success
  assert_output "2 lines"
}

@test "report_color_enabled" {
  local supported=1
  report_diff_color_supported || supported=0

  unset NO_COLOR

  BATS_HELPERS_REPORT_COLOR=0
  run report_color_enabled
  assert_failure

  # The suppression is what the override overrides, so the platform decides.
  BATS_HELPERS_REPORT_COLOR=1
  export NO_COLOR=1
  local overridden=1
  report_color_enabled || overridden=0
  assert_equal "${supported}" "${overridden}"

  unset BATS_HELPERS_REPORT_COLOR
  run report_color_enabled
  assert_failure

  unset NO_COLOR
  local automatic=1
  report_color_enabled || automatic=0
  assert_equal "${supported}" "${automatic}"
}

@test "report_diff_color_supported" {
  local probed=1
  diff --color=always /dev/null /dev/null >/dev/null 2>&1 || probed=0

  local reported=1
  report_diff_color_supported || reported=0

  assert_equal "${probed}" "${reported}"
}

@test "report_normalise_paths" {
  run report_normalise_paths "in ${PWD}/src and ${HOME}/somewhere"
  assert_success
  assert_output 'in ${PWD}/src and ${HOME}/somewhere'

  # The temporary directories nest, so each is rewritten to the closest name
  # rather than to the name of a directory holding it.
  run report_normalise_paths "${BATS_TEST_TMPDIR}/a ${BATS_FILE_TMPDIR}/b ${BATS_SUITE_TMPDIR}/c ${BATS_RUN_TMPDIR}/d"
  assert_success
  assert_output '${BATS_TEST_TMPDIR}/a ${BATS_FILE_TMPDIR}/b ${BATS_SUITE_TMPDIR}/c ${BATS_RUN_TMPDIR}/d'

  # The preprocessed copy bats-core runs is rewritten to the file that was
  # written, so a stack trace names something the consumer can open.
  run report_normalise_paths "${BATS_TEST_SOURCE}:12"
  assert_success
  assert_output '${PWD}/tests/assert.base.bats:12'

  run report_normalise_paths "nothing to rewrite"
  assert_success
  assert_output "nothing to rewrite"
}
