#!/usr/bin/env bats
#
# Tests for mock.
#
# shellcheck disable=SC2129

load _test_helper

@test "Mock: calls and arguments" {
  mock_curl=$(mock_command "curl")

  ./tests/fixtures/fixture.sh

  assert_equal 2 "$(mock_get_call_num "${mock_curl}")"

  assert_equal "-L -s -o /dev/null -w %{http_code} example.com" "$(mock_get_call_args "${mock_curl}" 1)"
  assert_equal "example.com" "$(mock_get_call_args "${mock_curl}" 2)"
}

@test "Mock: output" {
  mock_curl=$(mock_command "curl")
  mock_set_output "${mock_curl}" "testoutput1" 1
  mock_set_output "${mock_curl}" "testoutput2" 2

  run ./tests/fixtures/fixture.sh
  assert_success
  assert_equal 2 "$(mock_get_call_num "${mock_curl}")"
  assert_output_contains "testoutput1"
  assert_output_contains "testoutput2"
}

@test "Mock: exit status" {
  mock_curl=$(mock_command "curl")
  mock_set_status "${mock_curl}" 1 1

  run ./tests/fixtures/fixture.sh
  assert_failure
  assert_equal 1 "$(mock_get_call_num "${mock_curl}")"
}
