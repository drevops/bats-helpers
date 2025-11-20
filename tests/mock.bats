#!/usr/bin/env bats
#
# Tests for mock.
#
# shellcheck disable=SC2129,SC2030,SC2031

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

# Tests for enhanced mock_create with command parameter
@test "Mock: mock_create with command name" {
  mock_wget=$(mock_create wget)

  assert_equal "wget" "$(basename "${mock_wget}")"
  assert_file_exists "${mock_wget}"
  run test -x "${mock_wget}"
  assert_success
}

@test "Mock: mock_create command links to mock" {
  mock_wget=$(mock_create wget)

  run readlink "${mock_wget}"
  assert_success
  assert_output_contains "bats-mock.$$."
}

@test "Mock: mock_create command is in bats-mock.$$.bin directory" {
  mock_wget=$(mock_create wget)

  run dirname "${mock_wget}"
  assert_success
  assert_output_contains "bats-mock.$$.bin"
}

@test "Mock: mock_create without command (backward compatibility)" {
  mock=$(mock_create)

  run basename "${mock}"
  assert_success
  assert_output_contains "bats-mock.$$."
  assert_file_exists "${mock}"
  run test -x "${mock}"
  assert_success
}

@test "Mock: mock_create names programs uniquely" {
  mock1=$(mock_create)
  mock2=$(mock_create)

  run test "${mock1}" != "${mock2}"
  assert_success
}

@test "Mock: mock_create creates program in BATS_MOCK_TMPDIR" {
  mock=$(mock_create)
  expected_dir="${BATS_MOCK_TMPDIR}"

  run dirname "${mock}"
  assert_success
  assert_equal "${expected_dir}" "${output}"
}

@test "Mock: mock_create command with absolute path" {
  tmpdir="${BATS_MOCK_TMPDIR}"
  absolute_path="${tmpdir}/custom-path"
  mkdir -p "${absolute_path}"

  mock_wget=$(mock_create "${absolute_path}/wget")

  assert_equal "${absolute_path}/wget" "${mock_wget}"
  assert_file_exists "${mock_wget}"
}

@test "Mock: mock_create command with absolute path creates mock in BATS_TMPDIR" {
  tmpdir="${BATS_MOCK_TMPDIR}"
  absolute_path="${tmpdir}/custom-path"
  mkdir -p "${absolute_path}"

  mock_wget=$(mock_create "${absolute_path}/wget")

  # The symlink is at absolute_path, but it points to a mock in BATS_TMPDIR
  run readlink "${mock_wget}"
  assert_success
  run dirname "${output}"
  assert_equal "${tmpdir}" "${output}"
}

@test "Mock: mock_create command does not change PATH" {
  saved_path="${PATH}"

  mock_wget=$(mock_create wget)

  assert_equal "${saved_path}" "${PATH}"
}

@test "Mock: mock_create command twice with same name fails" {
  mock_wget=$(mock_create wget)

  run mock_create wget
  assert_failure
  assert_output_contains "File exists"
}

@test "Mock: mock_create with absolute path to existing command fails" {
  # Try to create a mock at an existing system command location
  run mock_create /bin/ls
  assert_failure
  # Error message varies by OS: "File exists" on Linux, "Operation not permitted" on macOS
}

# Tests for mock_teardown
@test "Mock: mock_teardown removes all mock files" {
  mock1=$(mock_create)
  mock2=$(mock_create curl)

  mock_teardown

  assert_file_not_exists "${mock1}"
  assert_file_not_exists "${mock2}"
}

@test "Mock: mock_teardown removes mock_chroot directory" {
  chroot_path=$(mock_chroot ls cat)

  mock_teardown

  assert_dir_not_exists "${chroot_path}"
}

# Tests for path_override
@test "Mock: path_override requires mock to be specified" {
  run path_override
  assert_failure
  assert_output_contains "Mock must be specified"
}

@test "Mock: path_override returns PATH prefixed with mock directory" {
  mock=$(mock_create)
  mock_dir=$(dirname "${mock}")

  run path_override "${mock}"
  assert_success
  assert_output_contains "${mock_dir}:"
}

@test "Mock: path_override works with directory" {
  mock=$(mock_create)
  mock_dir=$(dirname "${mock}")

  run path_override "${mock_dir}"
  assert_success
  assert_output_contains "${mock_dir}:"
}

@test "Mock: path_override with custom path" {
  run path_override "/x/y" "/a/b:/c/d"
  assert_success
  assert_equal "/x/y:/a/b:/c/d" "${output}"
}

@test "Mock: path_override is idempotent" {
  mock=$(mock_create)

  path1=$(path_override "${mock}")
  path2=$(path_override "${mock}" "${path1}")

  assert_equal "${path1}" "${path2}"
}

# Tests for path_rm
@test "Mock: path_rm requires path to be specified" {
  run path_rm
  assert_failure
  assert_output_contains "Path or command to remove must be specified"
}

@test "Mock: path_rm removes directory from PATH" {
  run path_rm "/usr/bin"
  assert_success
  run echo "${output}"
  assert_output_not_contains ":/usr/bin:"
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

@test "Mock: path_rm extracts directory from command" {
  cmd=$(command -v bash)
  path_to_cmd=$(dirname "${cmd}")

  result=$(path_rm "${cmd}")

  run echo ":${result}:"
  assert_output_not_contains ":${path_to_cmd}:"
}

# Tests for mock_chroot
@test "Mock: mock_chroot creates directory with default commands" {
  chroot_path=$(mock_chroot)

  # Test subset of created links
  run test -x "${chroot_path}/bash"
  assert_success
  run test -x "${chroot_path}/ls"
  assert_success
  run test -x "${chroot_path}/cat"
  assert_success
}

@test "Mock: mock_chroot is idempotent" {
  chroot1=$(mock_chroot)
  chroot2=$(mock_chroot)

  assert_equal "${chroot1}" "${chroot2}"
}

@test "Mock: mock_chroot shares directory with mock_create command" {
  mock_wget=$(mock_create wget)
  chroot_path=$(mock_chroot)

  assert_equal "$(dirname "${mock_wget}")" "${chroot_path}"
}

@test "Mock: mock_chroot with custom command list" {
  chroot_path=$(mock_chroot cat ls grep)

  run test -x "${chroot_path}/cat"
  assert_success
  run test -x "${chroot_path}/ls"
  assert_success
  run test -x "${chroot_path}/grep"
  assert_success
}

@test "Mock: mock_chroot custom list fails if command not found" {
  run mock_chroot cat nonexistent_command_12345 ls
  assert_failure
  assert_output_contains "command not found"
}

@test "Mock: mock_chroot does not overwrite existing mock" {
  # Create a mock cat command first
  mock_create cat >/dev/null

  chroot_path=$(mock_chroot)

  # Verify the mock is preserved (symlink still points to our mock)
  run readlink "${chroot_path}/cat"
  assert_success
  assert_output_contains "bats-mock.$$."
}

@test "Mock: mock_chroot custom list fails if mock already exists" {
  # Create a mock cat command first
  mock_create cat >/dev/null

  run mock_chroot ls cat head
  assert_failure
  assert_output_contains "File exists"
}

@test "Mock: mock_chroot skips missing commands in default mode" {
  # mock_chroot should succeed even if some commands don't exist
  # This is tested implicitly since some commands in the default list
  # (like tempfile, pidof) don't exist on all systems
  chroot_path=$(mock_chroot)

  # Should succeed
  assert_file_exists "${chroot_path}"

  # At least some commands should be linked (bash, ls, cat should exist everywhere)
  run test -L "${chroot_path}/bash"
  assert_success
}

# Integration test
@test "Mock: integration - combine path_override, path_rm and mock_chroot" {
  # Create mock command
  mock_wget=$(mock_create wget)

  # Create chroot with basic commands
  chroot_path=$(mock_chroot cat echo bash)

  # Verify mock and chroot share same directory
  assert_equal "$(dirname "${mock_wget}")" "${chroot_path}"

  # Build PATH with chroot and without /usr/bin
  test_path=$(path_override "${chroot_path}" "$(path_rm /usr/bin)")

  # Verify PATH contains chroot directory
  run echo "${test_path}"
  assert_output_contains "${chroot_path}"

  # Verify PATH doesn't contain /usr/bin
  run echo ":${test_path}:"
  assert_output_not_contains ":/usr/bin:"

  # Verify mock is accessible via PATH
  PATH="${test_path}" run command -v wget
  assert_success
  assert_output_contains "${mock_wget}"
}
