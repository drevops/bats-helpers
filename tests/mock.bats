#!/usr/bin/env bats
#
# Tests for mocking helpers.
#
# shellcheck disable=SC2129,SC2030,SC2031,SC2034

load _test_helper

# Matches the library's minimum, and silences the warning flags on 'run' emit.
bats_require_minimum_version 1.13.0

##
## Mocks.
##

@test "Mock: calls and arguments" {
  mock_curl=$(mock_command "curl")

  "${BATS_TEST_DIRNAME}/fixtures/mock_script.sh"

  assert_equal 2 "$(mock_get_call_num "${mock_curl}")"

  assert_equal "-L -s -o /dev/null -w %{http_code} example.com" "$(mock_get_call_args "${mock_curl}" 1)"
  assert_equal "example.com" "$(mock_get_call_args "${mock_curl}" 2)"
}

@test "Mock: output" {
  mock_curl=$(mock_command "curl")
  mock_set_output "${mock_curl}" "testoutput1" 1
  mock_set_output "${mock_curl}" "testoutput2" 2

  run "${BATS_TEST_DIRNAME}/fixtures/mock_script.sh"
  assert_success
  assert_equal 2 "$(mock_get_call_num "${mock_curl}")"
  assert_output_contains "testoutput1"
  assert_output_contains "testoutput2"
}

@test "Mock: output is written literally" {
  mock_curl=$(mock_command "curl")
  mock_set_output "${mock_curl}" "-n" 1
  mock_set_output "${mock_curl}" 'first\nsecond' 2

  run curl example.com
  assert_success
  assert_output "-n"

  run curl example.com
  assert_success
  assert_output 'first\nsecond'
}

@test "Mock: exit status" {
  mock_curl=$(mock_command "curl")
  mock_set_status "${mock_curl}" 1 1

  run "${BATS_TEST_DIRNAME}/fixtures/mock_script.sh"
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

@test "Mock: call user" {
  unset BATS_HELPERS_MOCK_USER
  unset _USER
  mock_curl=$(mock_command "curl")

  curl example.com
  assert_equal "$(id -un)" "$(mock_get_call_user "${mock_curl}")"

  export BATS_HELPERS_MOCK_USER="someoneelse"
  curl example.com

  assert_equal "someoneelse" "$(mock_get_call_user "${mock_curl}" 2)"
}

@test "Mock: default temporary directory" {
  assert_equal "${BATS_TEST_TMPDIR}/bats-helpers-mock" "${BATS_HELPERS_MOCK_TMPDIR}"

  mock_curl=$(mock_command "curl")

  assert_equal "${BATS_HELPERS_MOCK_TMPDIR}" "$(dirname "${mock_curl}")"
  assert_symlink_exists "${BATS_HELPERS_MOCK_TMPDIR}/curl"
}

@test "Mock: custom temporary directory" {
  export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/custom"

  run mock_prepare_tmp
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/bats-helpers-mock"

  # A trailing slash does not produce a double separator.
  export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/custom/"

  run mock_prepare_tmp
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/bats-helpers-mock"
}

@test "Mock: custom temporary directory with spaces" {
  export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/bats mock with spaces"
  mkdir -p "${BATS_HELPERS_MOCK_TMPDIR}"
  mock_curl=$(mock_command "curl")

  PATH="${BATS_HELPERS_MOCK_TMPDIR}":${PATH} run curl example.com

  assert_success
}

@test "Mock: custom temporary directory with shell metacharacters" {
  export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/\$(touch pwned) mock"
  mkdir -p "${BATS_HELPERS_MOCK_TMPDIR}"
  mock_curl=$(mock_command "curl")

  # The injected 'touch' would write to the mock process's working directory,
  # which it inherits from here, so the assertion below has to watch that one.
  cd "${BATS_TEST_TMPDIR}" || return 1

  PATH="${BATS_HELPERS_MOCK_TMPDIR}":${PATH} run curl example.com

  assert_success
  assert_file_not_exists "${BATS_TEST_TMPDIR}/pwned"
  assert_equal "curl 'example.com'" "$(mock_log_print)"
}

@test "Mock: temporary directory that cannot be created" {
  touch "${BATS_TEST_TMPDIR}/regular_file"
  export BATS_HELPERS_MOCK_TMPDIR="${BATS_TEST_TMPDIR}/regular_file/custom"

  run mock_prepare_tmp
  assert_failure
}

@test "Mock: temporary directory without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_HELPERS_MOCK_TMPDIR=""
  BATS_MOCK_TMPDIR=""
  BATS_TEST_TMPDIR=""
  run mock_prepare_tmp
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_output_contains "Set BATS_HELPERS_MOCK_TMPDIR to a writable directory"
}

@test "Mock: create without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_HELPERS_MOCK_TMPDIR=""
  BATS_MOCK_TMPDIR=""
  BATS_TEST_TMPDIR=""
  run mock_create
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_output_contains "Set BATS_HELPERS_MOCK_TMPDIR to a writable directory"
}

@test "Mock: paths" {
  mock_curl="$(mock_command "curl")"
  mock_git="$(mock_command "git")"

  assert_string_contains "$(mock_paths)" "${mock_curl}"
  assert_string_contains "$(mock_paths)" "${mock_git}"

  local original="${BATS_TEST_TMPDIR}"

  BATS_HELPERS_MOCK_TMPDIR=""
  BATS_MOCK_TMPDIR=""
  BATS_TEST_TMPDIR=""
  run mock_paths
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_output_contains "Set BATS_HELPERS_MOCK_TMPDIR to a writable directory"
}

@test "Mock: names" {
  mock_command "curl" >/dev/null
  mock_command "git" >/dev/null

  assert_string_contains "$(mock_names)" "curl"
  assert_string_contains "$(mock_names)" "git"

  local original="${BATS_TEST_TMPDIR}"

  BATS_HELPERS_MOCK_TMPDIR=""
  BATS_MOCK_TMPDIR=""
  BATS_TEST_TMPDIR=""
  run mock_names
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_output_contains "Set BATS_HELPERS_MOCK_TMPDIR to a writable directory"
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

@test "Mock: call environment when not called enough times" {
  mock_curl=$(mock_command "curl")

  curl example.com

  run mock_get_call_env "${mock_curl}" "MOCK_TEST_VAR" 2
  assert_failure
  assert_output_contains "Mock must be called at least 2 time(s)"
}

@test "Mock: call environment when not called enough times - caller recovers" {
  mock_curl=$(mock_command "curl")

  curl example.com

  recovered=0
  mock_get_call_env "${mock_curl}" "MOCK_TEST_VAR" 2 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

##
## Argument specifications.
##

@test "mock_spec_add" {
  mock_git="$(mock_command "git")"

  assert_equal "${mock_git}.spec.1" "$(mock_spec_add "${mock_git}")"
  assert_equal "${mock_git}.spec.2" "$(mock_spec_add "${mock_git}")"

  run mock_spec_add "${BATS_TEST_TMPDIR}/not_a_mock"
  assert_failure
  assert_output_contains "does not exist. Create it with 'mock_command' first."
}

@test "mock_spec_arg - equals" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"

  mock_spec_matches "${spec}" "status"

  run mock_spec_matches "${spec}" "log"
  assert_failure
  run mock_spec_matches "${spec}" "STATUS"
  assert_failure
  run mock_spec_matches "${spec}"
  assert_failure
}

@test "mock_spec_arg - not_equals" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 not_equals "status"

  mock_spec_matches "${spec}" "log"

  run mock_spec_matches "${spec}" "status"
  assert_failure
}

@test "mock_spec_arg - starts_with" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 starts_with "https://"

  mock_spec_matches "${spec}" "https://example.com"

  run mock_spec_matches "${spec}" "git@example.com"
  assert_failure
}

@test "mock_spec_arg - not_starts_with" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 not_starts_with "https://"

  mock_spec_matches "${spec}" "git@example.com"

  run mock_spec_matches "${spec}" "https://example.com"
  assert_failure
}

@test "mock_spec_arg - ends_with" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 ends_with ".git"

  mock_spec_matches "${spec}" "https://example.com/repo.git"

  run mock_spec_matches "${spec}" "https://example.com/repo"
  assert_failure
}

@test "mock_spec_arg - not_ends_with" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 not_ends_with ".git"

  mock_spec_matches "${spec}" "https://example.com/repo"

  run mock_spec_matches "${spec}" "https://example.com/repo.git"
  assert_failure
}

@test "mock_spec_arg - contains" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 contains "example"

  mock_spec_matches "${spec}" "https://example.com/repo.git"

  run mock_spec_matches "${spec}" "https://other.com/repo.git"
  assert_failure
}

@test "mock_spec_arg - not_contains" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 not_contains "example"

  mock_spec_matches "${spec}" "https://other.com/repo.git"

  run mock_spec_matches "${spec}" "https://example.com/repo.git"
  assert_failure
}

@test "mock_spec_arg - matches" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 matches '^v[0-9]+$'

  mock_spec_matches "${spec}" "v42"

  run mock_spec_matches "${spec}" "v42.1"
  assert_failure
  run mock_spec_matches "${spec}" "V42"
  assert_failure
}

@test "mock_spec_arg - not_matches" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 not_matches '^v[0-9]+$'

  mock_spec_matches "${spec}" "v42.1"

  run mock_spec_matches "${spec}" "v42"
  assert_failure
}

@test "mock_spec_arg - present" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 2 present

  mock_spec_matches "${spec}" "status" "--short"
  # An empty argument is still an argument.
  mock_spec_matches "${spec}" "status" ""

  run mock_spec_matches "${spec}" "status"
  assert_failure
}

@test "mock_spec_arg - not_present" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 2 not_present

  mock_spec_matches "${spec}" "status"

  run mock_spec_matches "${spec}" "status" "--short"
  assert_failure
}

@test "mock_spec_arg - any position" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" '*' equals "--force"

  mock_spec_matches "${spec}" "push" "--force"
  mock_spec_matches "${spec}" "--force" "push"

  run mock_spec_matches "${spec}" "push"
  assert_failure
}

@test "mock_spec_arg - any position, negated" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" '*' not_equals "--force"

  mock_spec_matches "${spec}" "push" "origin"

  # At '*' the negation requires that no argument matches.
  run mock_spec_matches "${spec}" "push" "--force"
  assert_failure
}

@test "mock_spec_arg - any position, present" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" '*' present

  mock_spec_matches "${spec}" "status"

  run mock_spec_matches "${spec}"
  assert_failure
}

@test "mock_spec_arg - repeated any position" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" '*' equals "--force"
  mock_spec_arg "${spec}" '*' equals "--quiet"

  mock_spec_matches "${spec}" "push" "--force" "--quiet"

  run mock_spec_matches "${spec}" "push" "--force"
  assert_failure
}

@test "mock_spec_arg - validation" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"

  run mock_spec_arg "${BATS_TEST_TMPDIR}/not_a_spec" 1 equals "status"
  assert_failure
  assert_output_contains "Create it with 'mock_spec_add' first."

  run mock_spec_arg "${spec}" 0 equals "status"
  assert_failure
  assert_output_contains "Position '0' is not a positive integer or '*'."

  run mock_spec_arg "${spec}" "first" equals "status"
  assert_failure
  assert_output_contains "Position 'first' is not a positive integer or '*'."

  run mock_spec_arg "${spec}" 2 startswith "https://"
  assert_failure
  assert_output_contains "Matcher 'startswith' is not known."

  run mock_spec_arg "${spec}" 2 present "value"
  assert_failure
  assert_output_contains "Matcher 'present' takes no value."

  run mock_spec_arg "${spec}" 2 equals
  assert_failure
  assert_output_contains "Matcher 'equals' requires a value."

  run mock_spec_arg "${spec}" 2 matches '['
  assert_failure
  assert_output_contains "Invalid regular expression '['."

  # A position constrained twice would make the outcome depend on which of the
  # two constraints was consulted first.
  run mock_spec_arg "${spec}" 1 contains "stat"
  assert_failure
  assert_output_contains "Position '1' is already constrained by this specification."
}

@test "mock_spec_count" {
  mock_git="$(mock_command "git")"
  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_count "${spec}" 2

  mock_spec_matches "${spec}" "status" "--short"

  run mock_spec_matches "${spec}" "status"
  assert_failure
  run mock_spec_matches "${spec}" "status" "--short" "--branch"
  assert_failure

  run mock_spec_count "${BATS_TEST_TMPDIR}/not_a_spec" 2
  assert_failure
  assert_output_contains "Create it with 'mock_spec_add' first."

  run mock_spec_count "${spec}" "two"
  assert_failure
  assert_output_contains "Count 'two' is not a non-negative integer."
}

@test "mock_match_value - unknown matcher" {
  run mock_match_value "value" "unknown" "needle"
  assert_failure
}

@test "mock_match_index - first matching specification wins" {
  mock_git="$(mock_command "git")"

  broad="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${broad}" 1 starts_with "s"
  mock_spec_set_output "${broad}" "broad"

  narrow="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${narrow}" 1 equals "status"
  mock_spec_set_output "${narrow}" "narrow"

  run git status
  assert_success
  assert_output "broad"

  assert_equal "1" "$(mock_match_index "${mock_git}" "status")"

  run mock_match_index "${mock_git}" "log"
  assert_failure
}

@test "mock_spec_set_status, mock_spec_set_output and mock_spec_set_side_effect" {
  mock_git="$(mock_command "git")"

  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "push"
  mock_spec_set_status "${spec}" 3
  mock_spec_set_output "${spec}" "rejected"
  mock_spec_set_side_effect "${spec}" "touch ${BATS_TEST_TMPDIR}/pushed"

  other="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${other}" 1 equals "status"
  mock_spec_set_output "${other}" "clean"

  run git push
  assert_failure --status 3
  assert_output "rejected"
  assert_file_exists "${BATS_TEST_TMPDIR}/pushed"

  run git status
  assert_success
  assert_output "clean"
}

@test "mock_spec_set_property - from STDIN" {
  mock_git="$(mock_command "git")"

  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"
  mock_spec_set_output "${spec}" - <<<"from stdin"

  run git status
  assert_success
  assert_output "from stdin"

  run mock_spec_set_output "${BATS_TEST_TMPDIR}/not_a_spec" "value"
  assert_failure
  assert_output_contains "Create it with 'mock_spec_add' first."
}

@test "mock_spec_set_property - the value is written literally" {
  mock_git="$(mock_command "git")"

  flag="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${flag}" 1 equals "status"
  mock_spec_set_output "${flag}" "-n"

  escape="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${escape}" 1 equals "log"
  mock_spec_set_output "${escape}" 'first\nsecond'

  run git status
  assert_success
  assert_output "-n"

  run git log
  assert_success
  assert_output 'first\nsecond'
}

@test "Specification response falls back to the per-call and default responses" {
  mock_git="$(mock_command "git")"
  mock_set_output "${mock_git}" "default output"
  mock_set_output "${mock_git}" "first call output" 1

  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"
  mock_spec_set_status "${spec}" 4

  run git status
  assert_failure --status 4
  assert_output "first call output"

  run git status
  assert_failure --status 4
  assert_output "default output"
}

@test "Argument specifications ignore the order of the calls" {
  mock_git="$(mock_command "git")"

  status_spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${status_spec}" 1 equals "status"
  mock_spec_set_output "${status_spec}" "clean"

  log_spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${log_spec}" 1 equals "log"
  mock_spec_set_output "${log_spec}" "commits"

  run git log
  assert_success
  assert_output "commits"

  run git status
  assert_success
  assert_output "clean"

  run git log
  assert_success
  assert_output "commits"
}

@test "mock_spec_describe" {
  mock_git="$(mock_command "git")"

  spec="$(mock_spec_add "${mock_git}")"
  assert_equal "any call" "$(mock_spec_describe "${spec}")"

  mock_spec_arg "${spec}" 1 equals "push"
  mock_spec_arg "${spec}" '*' not_equals "--force"
  mock_spec_arg "${spec}" 2 present
  mock_spec_count "${spec}" 3

  assert_equal "argument 1 equals 'push', some argument not_equals '--force', argument 2 present, 3 argument(s)" "$(mock_spec_describe "${spec}")"
}

@test "mock_spec_describe_all" {
  mock_git="$(mock_command "git")"

  assert_equal "" "$(mock_spec_describe_all "${mock_git}")"

  first="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${first}" 1 equals "status"

  second="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${second}" 1 equals "push"

  assert_equal "  specification 1: argument 1 equals 'status'
  specification 2: argument 1 equals 'push'" "$(mock_spec_describe_all "${mock_git}")"
}

@test "A call no specification accepts names the specifications" {
  mock_git="$(mock_command "git")"

  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"

  run git log
  assert_failure
  assert_output_contains "Mock 'git' received a call that no expectation covers: git 'log'"
  assert_output_contains "specification 1: argument 1 equals 'status'"

  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' received a call that no expectation covers: git 'log'"
  assert_output_contains "specification 1: argument 1 equals 'status'"
}

@test "mock_set_forward" {
  mock_basename="$(mock_command "basename")"
  mock_set_forward "${mock_basename}"

  spec="$(mock_spec_add "${mock_basename}")"
  mock_spec_arg "${spec}" 1 equals "mocked"
  mock_spec_set_output "${spec}" "from the mock"

  run basename mocked
  assert_success
  assert_output "from the mock"

  run basename "${BATS_TEST_TMPDIR}/real.txt"
  assert_success
  assert_output "real.txt"

  # The forwarded call is recorded like any other.
  mock_assert_calls "basename 'mocked'" "basename '${BATS_TEST_TMPDIR}/real.txt'"

  mock_set_forward "${mock_basename}" 0
  assert_file_not_exists "${mock_basename}.forward"

  run mock_set_forward "${mock_basename}" "yes"
  assert_failure
  assert_output_contains "Forwarding must be '0' or '1', got 'yes'."

  run mock_set_forward "${BATS_TEST_TMPDIR}/not_a_mock"
  assert_failure
  assert_output_contains "does not exist. Create it with 'mock_command' first."
}

@test "mock_set_forward - real command is not available" {
  mock_absent="$(mock_command "definitely_not_a_real_command")"
  mock_set_forward "${mock_absent}"

  # 'run -127' stops bats warning about the status it would otherwise read as a
  # mistake in the test.
  run -127 definitely_not_a_real_command
  assert_failure --status 127
  assert_output_contains "is not available to forward to"
}

@test "mock_set_forward - real command is a shell builtin" {
  mock_echo="$(mock_command "echo")"
  mock_set_forward "${mock_echo}"

  # A builtin resolves to a bare name, which the forwarded lookup has to
  # resolve outside the mock directory rather than back into the mock.
  run mock_forward_exec "${mock_echo}" "echo" "text"
  assert_success
  assert_output "text"
}

@test "mock_forward_path" {
  PATH="/one:${BATS_HELPERS_MOCK_TMPDIR}:/two" run mock_forward_path "${BATS_HELPERS_MOCK_TMPDIR}"
  assert_success
  assert_output "/one:/two"
}

##
## Strictness.
##

@test "A mock without expectations answers every call" {
  mock_git="$(mock_command "git")"

  run git status
  assert_success
  assert_output ""

  mock_verify
}

@test "A response without a call index answers every call" {
  mock_git="$(mock_command "git")"
  mock_set_output "${mock_git}" "anything"

  run git status
  assert_success
  assert_output "anything"

  run git log
  assert_success
  assert_output "anything"

  mock_verify
}

@test "A call no expectation covers fails the call" {
  mock_git="$(mock_command "git")"
  mock_set_status "${mock_git}" 0 1

  git status

  run git log
  assert_failure
  assert_output_contains "Mock 'git' received a call that no expectation covers: git 'log'"
}

@test "A call no expectation covers fails the verification" {
  mock_git="$(mock_command "git")"
  mock_set_status "${mock_git}" 0 1

  git status
  run git log
  assert_failure

  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' received a call that no expectation covers: git 'log'"
}

@test "A call an argument specification covers is not unexpected" {
  mock_git="$(mock_command "git")"

  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"

  run git status
  assert_success

  mock_verify

  run git log
  assert_failure
  assert_output_contains "Mock 'git' received a call that no expectation covers: git 'log'"
}

@test "An unused per-call response fails the verification" {
  mock_git="$(mock_command "git")"
  mock_set_status "${mock_git}" 0 1
  mock_set_output "${mock_git}" "second" 2

  git status

  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' has a response configured for call 2, but was called 1 time(s)"
}

@test "An unused argument specification fails the verification" {
  mock_git="$(mock_command "git")"

  used="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${used}" 1 equals "status"

  unused="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${unused}" 1 equals "log"

  git status

  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' argument specification 2 never accepted a call"
  assert_output_not_contains "argument specification 1"
}

@test "mock_verify - explicit mocks" {
  mock_git="$(mock_command "git")"
  mock_curl="$(mock_command "curl")"
  mock_set_status "${mock_git}" 0 1
  mock_set_status "${mock_curl}" 0 1

  git status

  # The unmet expectation of a mock that was not named is not reported.
  mock_verify "${mock_git}"

  run mock_verify "${mock_curl}"
  assert_failure
  assert_output_contains "Mock 'curl' has a response configured for call 1, but was called 0 time(s)"

  run mock_verify "${BATS_TEST_TMPDIR}/not_a_mock"
  assert_failure
  assert_output_contains "does not exist. Create it with 'mock_command' first."
}

@test "mock_verify - every mock of the test" {
  mock_git="$(mock_command "git")"
  mock_curl="$(mock_command "curl")"
  mock_set_status "${mock_git}" 0 1
  mock_set_status "${mock_git}" 0 2
  mock_set_status "${mock_curl}" 0 1

  git status

  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' has a response configured for call 2, but was called 1 time(s)"
  assert_output_contains "Mock 'curl' has a response configured for call 1, but was called 0 time(s)"
}

@test "mock_verify - no mocks" {
  mock_verify
}

@test "mock_set_strict" {
  mock_git="$(mock_command "git")"
  mock_set_status "${mock_git}" 0 1

  mock_set_strict "${mock_git}" 0

  run git status
  assert_success
  run git log
  assert_success

  mock_set_strict "${mock_git}"

  run git status
  assert_failure
  assert_output_contains "received a call that no expectation covers"

  run mock_set_strict "${mock_git}" "yes"
  assert_failure
  assert_output_contains "Strictness must be '0' or '1', got 'yes'."

  run mock_set_strict "${BATS_TEST_TMPDIR}/not_a_mock"
  assert_failure
  assert_output_contains "does not exist. Create it with 'mock_command' first."
}

@test "mock_strict_enabled" {
  mock_git="$(mock_command "git")"

  mock_strict_enabled "${mock_git}"

  mock_set_strict "${mock_git}" 0

  run mock_strict_enabled "${mock_git}"
  assert_failure

  run mock_strict_enabled "${BATS_TEST_TMPDIR}/not_a_mock"
  assert_failure
}

@test "BATS_HELPERS_MOCK_STRICT" {
  export BATS_HELPERS_MOCK_STRICT=0

  mock_git="$(mock_command "git")"
  mock_set_status "${mock_git}" 0 1
  mock_set_status "${mock_git}" 0 3

  run git status
  assert_success
  run git log
  assert_success

  # The verification still reports the expectations that went unmet.
  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' has a response configured for call 3, but was called 2 time(s)"
  assert_output_not_contains "no expectation covers"
}

@test "mock_expect_ordinal - an index is recorded once" {
  mock_git="$(mock_command "git")"
  mock_set_status "${mock_git}" 0 1
  mock_set_output "${mock_git}" "first" 1

  run mock_verify
  assert_failure
  assert_output_contains "Mock 'git' has a response configured for call 1, but was called 0 time(s)"

  assert_equal 1 "$(grep -c '^1$' "${mock_git}.expect_ordinal")"
}

@test "mock_has_expectations" {
  mock_git="$(mock_command "git")"

  run mock_has_expectations "${mock_git}"
  assert_failure

  mock_set_status "${mock_git}" 0 1

  mock_has_expectations "${mock_git}"
}

##
## Call log.
##

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
