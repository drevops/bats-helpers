#!/usr/bin/env bats
#
# Tests for mock argument specifications.
#
# shellcheck disable=SC2034

load _test_helper

# Matches the library's minimum, and silences the warning flags on 'run' emit.
bats_require_minimum_version 1.13.0

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

@test "Specification response falls back to the per-call and default responses" {
  mock_git="$(mock_command "git")"
  mock_set_output "${mock_git}" "default output"

  spec="$(mock_spec_add "${mock_git}")"
  mock_spec_arg "${spec}" 1 equals "status"
  mock_spec_set_status "${spec}" 4

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
  assert_output "commits"

  run git status
  assert_output "clean"

  run git log
  assert_output "commits"
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

@test "mock_forward_path" {
  PATH="/one:${BATS_HELPERS_MOCK_TMPDIR}:/two" run mock_forward_path "${BATS_HELPERS_MOCK_TMPDIR}"
  assert_success
  assert_output "/one:/two"
}
