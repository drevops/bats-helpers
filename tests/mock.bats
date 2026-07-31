#!/usr/bin/env bats
#
# Tests for mock.
#
# shellcheck disable=SC2129

load _test_helper

@test "Mock: calls and arguments" {
  mock_curl=$(mock_command "curl")

  "${BATS_TEST_DIRNAME}/fixtures/fixture.sh"

  assert_equal 2 "$(mock_get_call_num "${mock_curl}")"

  assert_equal "-L -s -o /dev/null -w %{http_code} example.com" "$(mock_get_call_args "${mock_curl}" 1)"
  assert_equal "example.com" "$(mock_get_call_args "${mock_curl}" 2)"
}

@test "Mock: output" {
  mock_curl=$(mock_command "curl")
  mock_set_output "${mock_curl}" "testoutput1" 1
  mock_set_output "${mock_curl}" "testoutput2" 2

  run "${BATS_TEST_DIRNAME}/fixtures/fixture.sh"
  assert_success
  assert_equal 2 "$(mock_get_call_num "${mock_curl}")"
  assert_output_contains "testoutput1"
  assert_output_contains "testoutput2"
}

@test "Mock: exit status" {
  mock_curl=$(mock_command "curl")
  mock_set_status "${mock_curl}" 1 1

  run "${BATS_TEST_DIRNAME}/fixtures/fixture.sh"
  assert_failure
  assert_equal 1 "$(mock_get_call_num "${mock_curl}")"
}

@test "Mock: assert call args - exact match" {
  mock_curl=$(mock_command "curl")

  curl -L -s -o /dev/null -w '%{http_code}' example.com

  run mock_assert_call_args "${mock_curl}" "-L -s -o /dev/null -w %{http_code} example.com" 1
  assert_success
}

@test "Mock: assert call args - wildcard match" {
  mock_curl=$(mock_command "curl")

  curl -L -s -o /dev/null -w '%{http_code}' example.com

  run mock_assert_call_args "${mock_curl}" "*" 1
  assert_success
}

@test "Mock: assert call args - exact mismatch" {
  mock_curl=$(mock_command "curl")

  curl -L -s -o /dev/null -w '%{http_code}' example.com

  run mock_assert_call_args "${mock_curl}" "different args" 1
  assert_failure
}

@test "Mock: assert call args - multiple calls with wildcard" {
  mock_curl=$(mock_command "curl")

  curl -L -s -o /dev/null -w '%{http_code}' example.com
  curl example.com

  run mock_assert_call_args "${mock_curl}" "*" 1
  assert_success

  run mock_assert_call_args "${mock_curl}" "*" 2
  assert_success
}

@test "Mock: not called enough times" {
  mock_curl=$(mock_command "curl")

  curl example.com

  run mock_default_n "${mock_curl}" 2
  assert_failure
  assert_output_contains "Mock must be called at least 2 time(s)"
}

@test "Mock: not called enough times - caller recovers" {
  mock_curl=$(mock_command "curl")

  curl example.com

  recovered=0
  mock_default_n "${mock_curl}" 2 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Mock: call args when not called enough times - caller recovers" {
  mock_curl=$(mock_command "curl")

  curl example.com

  recovered=0
  mock_get_call_args "${mock_curl}" 2 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Mock: call user when not called enough times - caller recovers" {
  mock_curl=$(mock_command "curl")

  curl example.com

  recovered=0
  mock_get_call_user "${mock_curl}" 2 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Mock: BATS_MOCK_TMPDIR with spaces" {
  export BATS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/bats mock with spaces"
  mkdir -p "${BATS_MOCK_TMPDIR}"
  mock_curl=$(mock_command "curl")

  PATH="${BATS_MOCK_TMPDIR}":${PATH} run curl example.com

  assert_success
}

@test "Mock: call environment" {
  mock_curl=$(mock_command "curl")

  MOCK_TEST_VAR="testvalue1" curl example.com
  MOCK_TEST_VAR="testvalue2" curl example.com

  assert_equal "testvalue1" "$(mock_get_call_env "${mock_curl}" "MOCK_TEST_VAR" 1)"
  assert_equal "testvalue2" "$(mock_get_call_env "${mock_curl}" "MOCK_TEST_VAR" 2)"
}

@test "Mock: call environment - default index" {
  mock_curl=$(mock_command "curl")

  MOCK_TEST_VAR="testvalue" curl example.com

  set -u
  actual="$(mock_get_call_env "${mock_curl}" "MOCK_TEST_VAR")"
  set +u

  assert_equal "testvalue" "${actual}"
}

@test "Mock: call environment when not called enough times - caller recovers" {
  mock_curl=$(mock_command "curl")

  curl example.com

  recovered=0
  mock_get_call_env "${mock_curl}" "MOCK_TEST_VAR" 2 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}
