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
  # shellcheck disable=SC2030
  export BATS_MOCK_TMPDIR="/tmp/bats mock with spaces"
  mkdir -p "${BATS_MOCK_TMPDIR}"
  mock_curl=$(mock_command "curl")

  # We have to modify the PATH since the setup_mock uses a different BATS_MOCK_TMPDIR
  PATH="$(path_prefix "${mock_curl}")" curl example.com
  assert_equal 1 "$(mock_get_call_num "${mock_curl}")"

  rm -rf "${BATS_MOCK_TMPDIR}"
}

# Tests for enhanced mock_create with command parameter
@test "Mock: mock_create with command name" {
  # Returns the newly created mock for 'wget' command
  mock_wget=$(mock_create wget)

  # Use the mocked 'wget'
  # @note: setup_mock will have already prepended the mock directory to PATH
  wget http://example.com/some-file
  assert_equal 1 "$(mock_get_call_num "${mock_wget}")"
}

@test "Mock: mock_create without command (backward compatibility)" {
  mock=$(mock_create)

  ${mock} foo
  assert_equal 1 "$(mock_get_call_num "${mock}")"
  assert_equal "foo" "$(mock_get_call_args "${mock}")"
}

@test "Mock: mock_create names programs uniquely" {
  mock1=$(mock_create)
  mock2=$(mock_create)

  test "${mock1}" != "${mock2}"
}

@test "Mock: mock_create command uses a directory unique to the test run" {
  mock_wget=$(mock_create wget)

  run dirname "${mock_wget}"
  assert_success
  # The directory should include the PID to avoid collisions with tests running
  # in parallel.
  assert_output_contains "bats-mock.$$.bin"
}

@test "Mock: mock_create creates program in BATS_MOCK_TMPDIR" {
  mock=$(mock_create)
  # shellcheck disable=SC2031
  expected_dir="${BATS_MOCK_TMPDIR}"

  run dirname "${mock}"
  assert_success
  assert_equal "${expected_dir}" "${output}"
}

@test "Mock: mock_create command with absolute path" {
  absolute_path="${BATS_TMPDIR}/custom-path"
  mkdir -p "${absolute_path}"

  mock_foo=$(mock_create "${absolute_path}/foo")
  assert_equal "${absolute_path}/foo" "${mock_foo}"

  # Adjust PATH, otherwise foo is not found
  PATH="$(path_prefix "${mock_foo}")" foo
  assert_equal 1 "$(mock_get_call_num "${mock_foo}")"
}

@test "Mock: mock_create command twice with same name fails" {
  mock_wget=$(mock_create wget)

  run mock_create wget
  assert_failure
  # Error message may vary by OS. The most likely reason is that someone tried
  # to mock an existing command.
  # TODO: Improve error message to be more specific.
  assert_output_contains "File exists"
}

@test "Mock: mock_create with absolute path to existing command fails" {
  # Try to create a mock at an existing system command location
  run mock_create /bin/ls
  assert_failure
  # Error message varies by OS: "File exists" on Linux, "Operation not permitted" on macOS
}

# Tests for teardown_mock
@test "Mock: teardown_mock removes all mock files" {
  mock1=$(mock_create)
  mock2=$(mock_create curl)

  teardown_mock

  assert_file_not_exists "${mock1}"
  assert_file_not_exists "${mock2}"
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
