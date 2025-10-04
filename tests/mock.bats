#!/usr/bin/env bats
#
# Tests for mock.
#

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

@test "Mock: BATS_MOCK_TMPDIR with spaces" {
  export BATS_MOCK_TMPDIR="/tmp/bats mock with spaces"
  mkdir -p "${BATS_MOCK_TMPDIR}"
  mock_curl=$(mock_command "curl")

  PATH="${BATS_MOCK_TMPDIR}":$PATH run curl example.com

  assert_success
  rm -rf "${BATS_MOCK_TMPDIR}"
}

# Tests for path_prefix
@test "Mock: path_prefix returns PATH prefixed with mock directory" {
  mock=$(mock_create)
  mock_dir=$(dirname "${mock}")

  run path_prefix "${mock}"
  assert_success
  assert_output_contains "${mock_dir}:"
}

@test "Mock: path_prefix requires mock to be specified" {
  run path_prefix
  assert_failure
  assert_output_contains "Mock must be specified"
}

@test "Mock: path_prefix works with directory" {
  mock=$(mock_create)
  mock_dir=$(dirname "${mock}")

  run path_prefix "${mock_dir}"
  assert_success
  assert_output_contains "${mock_dir}:"
}

@test "Mock: path_prefix with custom path" {
  run path_prefix "/x/y" "/a/b:/c/d"
  assert_success
  assert_equal "/x/y:/a/b:/c/d" "${output}"
}

@test "Mock: path_prefix is idempotent" {
  mock=$(mock_create)

  path1=$(path_prefix "${mock}")
  path2=$(path_prefix "${mock}" "${path1}")

  assert_equal "${path1}" "${path2}"
}

# Tests for path_rm
@test "Mock: path_rm removes directory from PATH" {
  run path_rm "/usr/bin"
  assert_success
  run echo "${output}"
  assert_output_not_contains ":/usr/bin:"
}

@test "Mock: path_rm requires path or command to be specified" {
  run path_rm
  assert_failure
  assert_output_contains "Path or command to remove must be specified"
}

@test "Mock: path_rm removes directory from custom path" {
  run path_rm "/a/b" "/c/d:/a/b:/e/f"
  assert_success
  assert_equal "/c/d:/e/f" "${output}"
}

@test "Mock: path_rm returns path unchanged if not contained" {
  run path_rm "/a/x" "/c/d:/a/b:/e/f"
  assert_success
  assert_equal "/c/d:/a/b:/e/f" "${output}"
}

@test "Mock: path_rm removes directory of command" {
  cmd=$(command -v bash)
  path_to_cmd=$(dirname "${cmd}")

  result=$(path_rm "${cmd}")

  run echo ":${result}:"
  assert_output_not_contains ":${path_to_cmd}:"
}
