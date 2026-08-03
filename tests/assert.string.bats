#!/usr/bin/env bats
#
# Tests for string assertions.
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

@test "string_random" {
  run string_random
  assert_success
  assert_equal 8 "${#output}"
  assert_empty "${output//[a-zA-Z0-9]/}"

  run string_random 16
  assert_success
  assert_equal 16 "${#output}"
  assert_empty "${output//[a-zA-Z0-9]/}"

  # A zero-padded length would be read as octal by the arithmetic loop.
  run string_random 08
  assert_success
  assert_equal 8 "${#output}"

  run string_random "abc"
  assert_failure
  assert_output_contains "Length must be a non-negative integer."
}

##
# Deprecated aliases.
#
# The calls below pass the needle first, so they fail if the alias stops
# reversing its arguments before forwarding.
##

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
