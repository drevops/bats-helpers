#!/usr/bin/env bats
#
# Tests for Bats helpers.
#
# Each assertion tests positive and negative behaviour.
#
# shellcheck disable=SC2129

load _test_helper

@test "assert_string_contains" {
  assert_string_contains "some needle in a haystack" "needle"
  assert_string_contains "some n[ee]dle in a haystack" "n[ee]dle"

  run assert_string_contains "some ne edle in a haystack" "needle"
  assert_failure
}

@test "assert_string_not_contains" {
  assert_string_not_contains "some needle in a haystack" "otherneedle"
  assert_string_not_contains "some n[ee]dle in a haystack" "othern[ee]dle"

  run assert_string_not_contains "some needle in a haystack" "needle"
  assert_failure
  run assert_string_not_contains "some n[ee]dle in a haystack" "n[ee]dle"
  assert_failure
}

@test "assert_equal" {
  assert_equal 1 1

  run assert_equal 1 2
  assert_failure
}

@test "assert_empty" {
  assert_empty ""

  run assert_empty "something"
  assert_failure
}

@test "assert_not_empty" {
  assert_not_empty "something"

  run assert_not_empty ""
  assert_failure
}

##
# Deprecated aliases.
#
# The calls below pass the needle first, so they fail if the alias stops
# reversing its arguments before forwarding.
##

@test "assert_contains" {
  export BATS_HELPERS_DEPRECATION_QUIET=1

  assert_contains "needle" "some needle in a haystack"
  assert_contains "n[ee]dle" "some n[ee]dle in a haystack"

  run assert_contains "needle" "some ne edle in a haystack"
  assert_failure
}

@test "assert_not_contains" {
  export BATS_HELPERS_DEPRECATION_QUIET=1

  assert_not_contains "otherneedle" "some needle in a haystack"
  assert_not_contains "othern[ee]dle" "some n[ee]dle in a haystack"

  run assert_not_contains "needle" "some needle in a haystack"
  assert_failure
  run assert_not_contains "n[ee]dle" "some n[ee]dle in a haystack"
  assert_failure
}
