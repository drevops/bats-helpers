#!/usr/bin/env bats
#
# Tests for string assertions.
#
# shellcheck disable=SC2129

load _test_helper

@test "assert_string_contains" {
  assert_string_contains "some needle in a haystack" "needle"
  assert_string_contains "some n[ee]dle in a haystack" "n[ee]dle"
  assert_string_contains "some NEEDLE in a haystack" "needle"
  assert_string_contains --case-sensitive "some needle in a haystack" "needle"
  assert_string_contains --regex "some needle 42 in a haystack" 'needle [0-9]+'
  assert_string_contains --format "Deleted 12 files in 0.5s" "Deleted %d files in %fs"
  assert_string_contains $'first line\nsecond line' $'line\nsecond'

  run assert_string_contains "some ne edle in a haystack" "needle"
  assert_failure
  run assert_string_contains --case-sensitive "some NEEDLE in a haystack" "needle"
  assert_failure
  run assert_string_contains --regex "some needle in a haystack" 'needle [0-9]+'
  assert_failure
  run assert_string_contains --format "Deleted some files" "Deleted %d files"
  assert_failure
}

@test "assert_string_not_contains" {
  assert_string_not_contains "some needle in a haystack" "otherneedle"
  assert_string_not_contains "some n[ee]dle in a haystack" "othern[ee]dle"
  assert_string_not_contains --case-sensitive "some NEEDLE in a haystack" "needle"
  assert_string_not_contains --regex "some needle in a haystack" 'needle [0-9]+'
  assert_string_not_contains --format "Deleted some files" "Deleted %d files"

  run assert_string_not_contains "some needle in a haystack" "needle"
  assert_failure
  run assert_string_not_contains "some n[ee]dle in a haystack" "n[ee]dle"
  assert_failure
  run assert_string_not_contains "some NEEDLE in a haystack" "needle"
  assert_failure
  run assert_string_not_contains --regex "some needle 42 in a haystack" 'needle [0-9]+'
  assert_failure
}

@test "assert_string_starts_with" {
  assert_string_starts_with "some needle" "some"
  assert_string_starts_with "some needle" "SOME"
  assert_string_starts_with --case-sensitive "some needle" "some"
  assert_string_starts_with --regex "42 needles" '[0-9]+'
  assert_string_starts_with --format "42 needles" "%d needles"

  # The anchor applies to the whole string, not to each of its lines.
  assert_string_starts_with $'first\nsecond' "first"

  run assert_string_starts_with "some needle" "needle"
  assert_failure
  run assert_string_starts_with --case-sensitive "some needle" "SOME"
  assert_failure
  run assert_string_starts_with $'first\nsecond' "second"
  assert_failure
}

@test "assert_string_not_starts_with" {
  assert_string_not_starts_with "some needle" "needle"
  assert_string_not_starts_with --case-sensitive "some needle" "SOME"
  assert_string_not_starts_with --regex "some needle" '[0-9]+'
  assert_string_not_starts_with $'first\nsecond' "second"

  run assert_string_not_starts_with "some needle" "some"
  assert_failure
  run assert_string_not_starts_with "some needle" "SOME"
  assert_failure
  run assert_string_not_starts_with --regex "42 needles" '[0-9]+'
  assert_failure
}

@test "assert_string_ends_with" {
  assert_string_ends_with "some needle" "needle"
  assert_string_ends_with "some needle" "NEEDLE"
  assert_string_ends_with --case-sensitive "some needle" "needle"
  assert_string_ends_with --regex "needles 42" '[0-9]+'
  assert_string_ends_with --format "took 0.5s" "took %fs"

  # The anchor applies to the whole string, not to each of its lines.
  assert_string_ends_with $'first\nsecond' "second"

  run assert_string_ends_with "some needle" "some"
  assert_failure
  run assert_string_ends_with --case-sensitive "some needle" "NEEDLE"
  assert_failure
  run assert_string_ends_with $'first\nsecond' "first"
  assert_failure
}

@test "assert_string_not_ends_with" {
  assert_string_not_ends_with "some needle" "some"
  assert_string_not_ends_with --case-sensitive "some needle" "NEEDLE"
  assert_string_not_ends_with --regex "some needle" '[0-9]+'
  assert_string_not_ends_with $'first\nsecond' "first"

  run assert_string_not_ends_with "some needle" "needle"
  assert_failure
  run assert_string_not_ends_with "some needle" "NEEDLE"
  assert_failure
  run assert_string_not_ends_with --regex "needles 42" '[0-9]+'
  assert_failure
}

@test "assert_string_matches" {
  assert_string_matches "some needle 42" 'needle [0-9]+'
  assert_string_matches "some NEEDLE 42" 'needle [0-9]+'
  assert_string_matches --case-sensitive "some needle 42" 'needle [0-9]+'
  assert_string_matches "some needle" '^some'
  assert_string_matches "some needle" 'needle$'

  # The anchors apply to the whole string, not to each of its lines.
  run assert_string_matches $'first\nsecond' '^second'
  assert_failure

  run assert_string_matches "some needle" 'needle [0-9]+'
  assert_failure
  run assert_string_matches --case-sensitive "some NEEDLE 42" 'needle [0-9]+'
  assert_failure
}

@test "assert_string_not_matches" {
  assert_string_not_matches "some needle" 'needle [0-9]+'
  assert_string_not_matches --case-sensitive "some NEEDLE 42" 'needle [0-9]+'
  assert_string_not_matches $'first\nsecond' '^second'

  run assert_string_not_matches "some needle 42" 'needle [0-9]+'
  assert_failure
  run assert_string_not_matches "some NEEDLE 42" 'needle [0-9]+'
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

@test "string_match" {
  run string_match "some needle" "NEEDLE" "literal" 0 "anywhere"
  assert_success
  run string_match "some needle" "NEEDLE" "literal" 1 "anywhere"
  [ "${status}" -eq 1 ]

  run string_match "some needle" "some" "literal" 1 "start"
  assert_success
  run string_match "some needle" "needle" "literal" 1 "start"
  [ "${status}" -eq 1 ]

  run string_match "some needle" "needle" "literal" 1 "end"
  assert_success
  run string_match "some needle" "some" "literal" 1 "end"
  [ "${status}" -eq 1 ]

  run string_match "some needle 42" 'needle [0-9]+' "regex" 1 "anywhere"
  assert_success
  run string_match "some needle" 'needle [0-9]+' "regex" 1 "anywhere"
  [ "${status}" -eq 1 ]

  run string_match "some needle" 'SOME' "regex" 0 "start"
  assert_success
  run string_match "some needle" 'SOME' "regex" 1 "start"
  [ "${status}" -eq 1 ]

  run string_match "some needle" 'NEEDLE' "regex" 0 "end"
  assert_success
  run string_match "some needle" 'NEEDLE' "regex" 1 "end"
  [ "${status}" -eq 1 ]

  run string_match "some needle" "[" "regex" 1 "anywhere"
  [ "${status}" -eq 2 ]
}

@test "string_match leaves the shell's case matching option alone" {
  local was_set

  shopt -u nocasematch
  string_match "some needle" "absent" "literal" 0 "anywhere" || true
  was_set=0
  if shopt -q nocasematch; then was_set=1; fi
  assert_equal 0 "${was_set}"

  shopt -s nocasematch
  string_match "some needle" "absent" "literal" 1 "anywhere" || true
  was_set=0
  if shopt -q nocasematch; then was_set=1; fi
  assert_equal 1 "${was_set}"

  shopt -u nocasematch
}

@test "string_format_to_regex" {
  run string_format_to_regex "Deleted %d files"
  assert_success
  assert_equal 'Deleted [0-9]+ files' "${output}"

  run string_format_to_regex "took %fs"
  assert_success
  assert_equal 'took [0-9]+(\.[0-9]+)?s' "${output}"

  run string_format_to_regex "user %s logged in"
  assert_success
  assert_equal 'user [^[:space:]]+ logged in' "${output}"

  run string_format_to_regex "100%% done"
  assert_success
  assert_equal '100% done' "${output}"

  run string_format_to_regex '.|$()[]{}?+*^\'
  assert_success
  assert_equal '\.\|\$\(\)\[\]\{\}\?\+\*\^\\' "${output}"

  run string_format_to_regex ""
  assert_success
  assert_equal "" "${output}"

  run string_format_to_regex "%z"
  assert_failure
  assert_output_contains "Unknown format placeholder '%z'. Use '%d', '%f', '%s' or '%%'."

  run string_format_to_regex "100%"
  assert_failure
  assert_output_contains "Unknown format placeholder '%'."
}

@test "Match mode options" {
  # Only an exact option is consumed, so a needle that looks like one is not.
  run echo "usage: --verbose enables logging"
  assert_output_contains "--verbose"

  # A needle that is exactly an option is reached through the terminator.
  run echo "the --regex option"
  assert_output_contains -- "--regex"

  # A positional argument is never read as an option.
  assert_string_contains "--regex and more" "--regex"
  assert_string_contains "some -- text" "--"

  # Repeating an option is harmless.
  assert_string_contains --regex --regex "some needle" 'n..dle'
  assert_string_contains --case-sensitive --case-sensitive "some needle" "needle"

  run assert_string_contains --literal --regex "some needle" "needle"
  assert_failure
  assert_output_contains "Conflicting match modes '--literal' and '--regex'."

  run assert_string_contains --ignore-case --case-sensitive "some needle" "needle"
  assert_failure
  assert_output_contains "Conflicting case options '--ignore-case' and '--case-sensitive'."

  run assert_string_contains "some needle"
  assert_failure
  assert_output_contains "A haystack and a needle are required."

  run echo "some needle"
  run assert_output_contains "some" "extra"
  assert_failure
  assert_output_contains "Unexpected argument 'extra'. Match mode options come before the positional arguments."

  run assert_string_matches "some needle" "["
  assert_failure
  assert_output_contains "Invalid regular expression '['."

  run assert_string_contains --format "some needle" "%z"
  assert_failure
  assert_output_contains "Unknown format placeholder '%z'."
}

@test "Failure report names the match mode and the case sensitivity" {
  run assert_string_contains --case-sensitive "some text" "SOME"
  assert_failure
  assert_output_contains "String 'some text' does not contain 'SOME'"
  assert_output_contains "match mode: literal"
  assert_output_contains "case: sensitive"
  assert_output_contains "note: it matches with '--ignore-case'"

  run assert_string_not_contains "some text" "SOME"
  assert_failure
  assert_output_contains "String 'some text' contains 'SOME', but should not"
  assert_output_contains "case: insensitive"
  assert_output_contains "note: it does not match with '--case-sensitive'"

  # Case did not decide the outcome, so it is not called out. The previous
  # capture is cleared because 'format_error' appends it to the report.
  output=""
  run assert_string_contains "some text" "absent"
  assert_failure
  assert_output_contains "case: insensitive"
  assert_output_not_contains "note:"

  run assert_string_matches "some text" '^absent'
  assert_failure
  assert_output_contains "String 'some text' does not match '^absent'"
  assert_output_contains "match mode: regex"

  run assert_string_not_matches "some text" '^some'
  assert_failure
  assert_output_contains "String 'some text' matches '^some', but should not"

  run assert_string_contains --format "Deleted some files" "Deleted %d files"
  assert_failure
  assert_output_contains "String 'Deleted some files' does not match 'Deleted %d files'"
  assert_output_contains "match mode: format"

  run assert_string_starts_with "some text" "text"
  assert_failure
  assert_output_contains "String 'some text' does not start with 'text'"

  run assert_string_not_starts_with "some text" "some"
  assert_failure
  assert_output_contains "String 'some text' starts with 'some', but should not"

  run assert_string_ends_with "some text" "some"
  assert_failure
  assert_output_contains "String 'some text' does not end with 'some'"

  run assert_string_not_ends_with "some text" "text"
  assert_failure
  assert_output_contains "String 'some text' ends with 'text', but should not"
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
