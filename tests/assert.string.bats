#!/usr/bin/env bats
#
# Tests for Bats helpers.
#
# Each assertion tests positive and negative behaviour.
#
# shellcheck disable=SC2129

load _test_helper

@test "assert_contains" {
  assert_contains "needle" "some needle in a haystack"
  assert_contains "n[ee]dle" "some n[ee]dle in a haystack"

  run assert_contains "needle" "some ne edle in a haystack"
  assert_failure
}

@test "assert_not_contains" {
  assert_not_contains "otherneedle" "some needle in a haystack"
  assert_not_contains "othern[ee]dle" "some n[ee]dle in a haystack"

  run assert_not_contains "needle" "some needle in a haystack"
  assert_failure
  run assert_not_contains "n[ee]dle" "some n[ee]dle in a haystack"
  assert_failure
}
