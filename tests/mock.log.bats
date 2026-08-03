#!/usr/bin/env bats
#
# Tests for the ordered mock call log.
#
# shellcheck disable=SC2030,SC2031,SC2034

load _test_helper

@test "mock_log_quote" {
  assert_equal "'value'" "$(mock_log_quote "value")"
  assert_equal "''" "$(mock_log_quote "")"
  assert_equal "''" "$(mock_log_quote)"
  assert_equal "'two words'" "$(mock_log_quote "two words")"
  assert_equal "' leading and trailing '" "$(mock_log_quote " leading and trailing ")"
  assert_equal "'it\\'s'" "$(mock_log_quote "it's")"
  assert_equal "'back\\\\slash'" "$(mock_log_quote 'back\slash')"
  assert_equal "'tab\\tseparated'" "$(mock_log_quote "$(printf 'tab\tseparated')")"
  assert_equal "'first\\nsecond'" "$(mock_log_quote "$(printf 'first\nsecond')")"
}

@test "mock_log_line" {
  assert_equal "git" "$(mock_log_line "git")"
  assert_equal "git 'status'" "$(mock_log_line "git" "status")"
  assert_equal "git 'commit' '-m' 'two words'" "$(mock_log_line "git" "commit" "-m" "two words")"
  assert_equal "git '' 'after empty'" "$(mock_log_line "git" "" "after empty")"
}

@test "mock_log_path" {
  assert_equal "${BATS_HELPERS_MOCK_TMPDIR}/mock.log" "$(mock_log_path)"
}

@test "mock_log_print" {
  mock_command "curl" >/dev/null

  assert_equal "" "$(mock_log_print)"

  curl example.com

  assert_equal "curl 'example.com'" "$(mock_log_print)"
}

@test "mock_log_calls_of" {
  mock_command "curl" >/dev/null
  mock_command "git" >/dev/null

  assert_equal "" "$(mock_log_calls_of "curl")"

  curl example.com
  git status

  assert_equal "curl 'example.com'" "$(mock_log_calls_of "curl")"
  assert_equal "git 'status'" "$(mock_log_calls_of "git")"
}

@test "mock_log_registered" {
  mock_command "curl" >/dev/null

  mock_log_registered "curl"

  run mock_log_registered "crul"
  assert_failure
}

@test "mock_log_exclude" {
  mock_command "curl" >/dev/null
  mock_command "logger" >/dev/null

  mock_log_exclude "logger"

  logger "noise"
  curl example.com

  # The call is recorded and stays visible outside sequence comparisons.
  assert_string_contains "$(mock_log_print)" "logger 'noise'"
  mock_assert_called "logger"

  mock_assert_calls "curl 'example.com'"

  run mock_log_exclude
  assert_failure
  assert_output_contains "At least one command name is required."
}

@test "mock_assert_calls" {
  mock_command "curl" >/dev/null
  mock_command "git" >/dev/null

  "${BATS_TEST_DIRNAME}/fixtures/mock_interleaved.sh"

  mock_assert_calls \
    "git 'clone' 'https://example.com/repo.git'" \
    "curl '-s' 'https://example.com/hook'" \
    "git 'checkout' 'main'"

  # The order of the calls is part of the assertion.
  run mock_assert_calls \
    "curl '-s' 'https://example.com/hook'" \
    "git 'clone' 'https://example.com/repo.git'" \
    "git 'checkout' 'main'"
  assert_failure
  assert_output_contains "Call log does not match the expected sequence"
  assert_output_contains "--- expected"
  assert_output_contains "+++ actual"

  run mock_assert_calls "git 'clone' 'https://example.com/repo.git'"
  assert_failure
}

@test "mock_assert_calls - empty and whitespace arguments" {
  mock_command "curl" >/dev/null

  curl "" "two words" " padded "

  mock_assert_calls "curl '' 'two words' ' padded '"

  # An empty argument is not the same as an absent one.
  run mock_assert_calls "curl 'two words' ' padded '"
  assert_failure
}

@test "mock_assert_no_calls" {
  mock_command "curl" >/dev/null

  mock_assert_no_calls

  curl example.com

  run mock_assert_no_calls
  assert_failure
  assert_output_contains "Mocked commands were called, but none should have been"
  assert_output_contains "curl 'example.com'"
}

@test "mock_assert_called" {
  mock_command "curl" >/dev/null
  mock_command "git" >/dev/null

  curl example.com

  mock_assert_called "curl"

  run mock_assert_called "git"
  assert_failure
  assert_output_contains "Command 'git' was not called"

  run mock_assert_called "crul"
  assert_failure
  assert_output_contains "Command 'crul' is not mocked. Register it with 'mock_command' first."
}

@test "mock_assert_not_called" {
  mock_command "curl" >/dev/null
  mock_command "git" >/dev/null

  curl example.com

  mock_assert_not_called "git"

  run mock_assert_not_called "curl"
  assert_failure
  assert_output_contains "Command 'curl' was called, but should not have been"
  assert_output_contains "curl 'example.com'"

  run mock_assert_not_called "crul"
  assert_failure
  assert_output_contains "Command 'crul' is not mocked. Register it with 'mock_command' first."
}

@test "Log path without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_HELPERS_MOCK_TMPDIR=""
  BATS_MOCK_TMPDIR=""
  BATS_TEST_TMPDIR=""
  run mock_log_path
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_output_contains "Set BATS_HELPERS_MOCK_TMPDIR to a writable directory"
}

@test "Sequence assertion without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_HELPERS_MOCK_TMPDIR=""
  BATS_MOCK_TMPDIR=""
  BATS_TEST_TMPDIR=""
  run mock_assert_calls "curl 'example.com'"
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_output_contains "Set BATS_HELPERS_MOCK_TMPDIR to a writable directory"
}

@test "Log covers a mock created without a command name" {
  mock="$(mock_create)"

  "${mock}" --flag

  assert_equal "${mock##*/} '--flag'" "$(mock_log_print)"
}
