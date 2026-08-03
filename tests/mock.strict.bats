#!/usr/bin/env bats
#
# Tests for mock expectation verification.
#
# shellcheck disable=SC2034

load _test_helper

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
