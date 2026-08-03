#!/usr/bin/env bats
#
# Tests for line assertions.
#

load _test_helper

# Matches the library's minimum, and silences the warning flags on 'run' emit.
bats_require_minimum_version 1.13.0

# The output the index and any-line assertions read.
capture() {
  run printf '%s\n' "Usage: tool.sh" "Reading config" "Deleted 12 files" "Done."
}

# The output the count assertions read, split evenly between the lines a needle
# matches and the lines it does not.
capture_counted() {
  run printf '%s\n' "error one" "ok" "error two" "ok"
}

# The output the format count assertions read.
capture_formatted() {
  run printf '%s\n' "Deleted 12 files" "ok" "Deleted 3 files"
}

# The same, with one of the two matching lines cased differently.
capture_formatted_mixed() {
  run printf '%s\n' "Deleted 12 files" "ok" "DELETED 3 files"
}

##
## Line assertions.
##

@test "assert_line" {
  capture
  assert_line 0 "Usage: tool.sh"
  assert_line 3 "Done."

  # A negative index counts back from the last line.
  assert_line -1 "Done."
  assert_line -4 "Usage: tool.sh"

  capture
  run assert_line 0 "Reading config"
  assert_failure
  assert_output_contains "Line 0 does not equal 'Reading config'"
  assert_output_contains "> 0: Usage: tool.sh"

  # The line reached through a negative index is named both ways.
  capture
  run assert_line -1 "Usage: tool.sh"
  assert_failure
  assert_output_contains "Line 3 (from index -1) does not equal 'Usage: tool.sh'"

  # An index outside the captured lines is an error rather than a comparison
  # against an empty string, at either end.
  capture
  run assert_line 4 "Done."
  assert_failure
  assert_output_contains "Line index 4 is out of range for output with 4 lines."

  capture
  run assert_line -5 "Usage: tool.sh"
  assert_failure
  assert_output_contains "Line index -5 is out of range for output with 4 lines."
}

@test "assert_line_not" {
  capture
  assert_line_not 0 "Reading config"
  assert_line_not -1 "Usage: tool.sh"

  capture
  run assert_line_not 0 "Usage: tool.sh"
  assert_failure
  assert_output_contains "Line 0 equals 'Usage: tool.sh', but should not"
  assert_output_contains "> 0: Usage: tool.sh"
}

##
## Line containment assertions.
##

@test "assert_line_contains" {
  capture
  assert_line_contains 1 "config"
  assert_line_contains 1 "CONFIG"
  assert_line_contains -1 "Done"

  capture
  run assert_line_contains 1 "absent"
  assert_failure
  assert_output_contains "Line 1 does not contain 'absent'"
  assert_output_contains "match mode: literal"
  assert_output_contains "case: insensitive"
  assert_output_contains "> 1: Reading config"

  capture
  run assert_line_contains 9 "config"
  assert_failure
  assert_output_contains "Line index 9 is out of range for output with 4 lines."
}

@test "assert_line_contains_case" {
  capture
  assert_line_contains_case 1 "config"

  capture
  run assert_line_contains_case 1 "CONFIG"
  assert_failure
  assert_output_contains "Line 1 does not contain 'CONFIG'"
  assert_output_contains "case: sensitive"
  assert_output_contains "note: it matches without the '_case' suffix"
}

@test "assert_line_not_contains" {
  capture
  assert_line_not_contains 1 "absent"

  capture
  run assert_line_not_contains 1 "config"
  assert_failure
  assert_output_contains "Line 1 contains 'config', but should not"

  capture
  run assert_line_not_contains 1 "CONFIG"
  assert_failure
  assert_output_contains "Line 1 contains 'CONFIG', but should not"
}

@test "assert_line_not_contains_case" {
  capture
  assert_line_not_contains_case 1 "CONFIG"
  assert_line_not_contains_case 1 "absent"

  capture
  run assert_line_not_contains_case 1 "config"
  assert_failure
  assert_output_contains "Line 1 contains 'config', but should not"
}

##
## Line regular expression assertions.
##

@test "assert_line_matches" {
  capture
  assert_line_matches 2 'Deleted [0-9]+ files'
  assert_line_matches 2 'DELETED [0-9]+ files'
  assert_line_matches 2 '^Deleted'
  assert_line_matches 2 'files$'

  capture
  run assert_line_matches 2 'Deleted [a-z]+ files'
  assert_failure
  assert_output_contains "Line 2 does not match 'Deleted [a-z]+ files'"
  assert_output_contains "match mode: regex"
  assert_output_contains "> 2: Deleted 12 files"
}

@test "assert_line_matches_case" {
  capture
  assert_line_matches_case 2 'Deleted [0-9]+ files'

  capture
  run assert_line_matches_case 2 'DELETED [0-9]+ files'
  assert_failure
  assert_output_contains "case: sensitive"
  assert_output_contains "note: it matches without the '_case' suffix"
}

@test "assert_line_not_matches" {
  capture
  assert_line_not_matches 2 'Deleted [a-z]+ files'

  capture
  run assert_line_not_matches 2 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "Line 2 matches 'Deleted [0-9]+ files', but should not"
}

@test "assert_line_not_matches_case" {
  capture
  assert_line_not_matches_case 2 'DELETED [0-9]+ files'

  capture
  run assert_line_not_matches_case 2 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "Line 2 matches 'Deleted [0-9]+ files', but should not"
}

##
## Line format assertions.
##

@test "assert_line_matches_format" {
  capture
  assert_line_matches_format 2 "Deleted %d files"
  assert_line_matches_format 2 "DELETED %d files"

  capture
  run assert_line_matches_format 2 "Deleted %d directories"
  assert_failure
  assert_output_contains "Line 2 does not match 'Deleted %d directories'"
  assert_output_contains "match mode: format"

  capture
  run assert_line_matches_format 2 "Deleted %z files"
  assert_failure
  assert_output_contains "Unknown format placeholder '%z'."
}

@test "assert_line_matches_format_case" {
  capture
  assert_line_matches_format_case 2 "Deleted %d files"

  capture
  run assert_line_matches_format_case 2 "DELETED %d files"
  assert_failure
  assert_output_contains "case: sensitive"
}

@test "assert_line_not_matches_format" {
  capture
  assert_line_not_matches_format 2 "Deleted %d directories"

  capture
  run assert_line_not_matches_format 2 "Deleted %d files"
  assert_failure
  assert_output_contains "Line 2 matches 'Deleted %d files', but should not"
}

@test "assert_line_not_matches_format_case" {
  capture
  assert_line_not_matches_format_case 2 "DELETED %d files"

  capture
  run assert_line_not_matches_format_case 2 "Deleted %d files"
  assert_failure
  assert_output_contains "Line 2 matches 'Deleted %d files', but should not"
}

##
## Any line assertions.
##

@test "assert_any_line" {
  capture
  assert_any_line "Done."
  assert_any_line "Usage: tool.sh"

  capture
  run assert_any_line "absent"
  assert_failure
  assert_output_contains "Output has no line equal to 'absent'"
}

@test "assert_no_line" {
  capture
  assert_no_line "absent"

  # An exact comparison, so a line that merely contains it does not count.
  assert_no_line "Done"

  capture
  run assert_no_line "Done."
  assert_failure
  assert_output_contains "Output has a line equal to 'Done.', but should not"
  assert_output_contains "> 3: Done."
}

##
## Any line containment assertions.
##

@test "assert_any_line_contains" {
  capture
  assert_any_line_contains "config"
  assert_any_line_contains "CONFIG"

  capture
  run assert_any_line_contains "absent"
  assert_failure
  assert_output_contains "Output has no line containing 'absent'"
  assert_output_contains "match mode: literal"
}

@test "assert_any_line_contains_case" {
  capture
  assert_any_line_contains_case "config"

  capture
  run assert_any_line_contains_case "CONFIG"
  assert_failure
  assert_output_contains "Output has no line containing 'CONFIG'"
  assert_output_contains "case: sensitive"
  assert_output_contains "note: it matches without the '_case' suffix"
}

@test "assert_no_line_contains" {
  capture
  assert_no_line_contains "absent"

  capture
  run assert_no_line_contains "config"
  assert_failure
  assert_output_contains "Output has a line containing 'config', but should not"
  assert_output_contains "> 1: Reading config"

  # Only the case setting let this one through, so it is named.
  capture
  run assert_no_line_contains "CONFIG"
  assert_failure
  assert_output_contains "note: it does not match with the '_case' suffix"
}

@test "assert_no_line_contains_case" {
  capture
  assert_no_line_contains_case "CONFIG"

  capture
  run assert_no_line_contains_case "config"
  assert_failure
  assert_output_contains "Output has a line containing 'config', but should not"
  assert_output_contains "case: sensitive"
}

##
## Any line regular expression assertions.
##

@test "assert_any_line_matches" {
  capture
  assert_any_line_matches 'Deleted [0-9]+ files'

  capture
  run assert_any_line_matches 'Deleted [a-z]+ files'
  assert_failure
  assert_output_contains "Output has no line matching 'Deleted [a-z]+ files'"
  assert_output_contains "match mode: regex"

  # An unusable expression is an error rather than an absence of matches.
  capture
  run assert_any_line_matches '['
  assert_failure
  assert_output_contains "Invalid regular expression '['."
}

@test "assert_any_line_matches_case" {
  capture
  assert_any_line_matches_case 'Deleted [0-9]+ files'

  capture
  run assert_any_line_matches_case 'DELETED [0-9]+ files'
  assert_failure
  assert_output_contains "case: sensitive"
}

@test "assert_no_line_matches" {
  capture
  assert_no_line_matches 'Deleted [a-z]+ files'

  capture
  run assert_no_line_matches 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "Output has a line matching 'Deleted [0-9]+ files', but should not"
  assert_output_contains "> 2: Deleted 12 files"
}

@test "assert_no_line_matches_case" {
  capture
  assert_no_line_matches_case 'DELETED [0-9]+ files'

  capture
  run assert_no_line_matches_case 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "Output has a line matching 'Deleted [0-9]+ files', but should not"
}

##
## Any line format assertions.
##

@test "assert_any_line_matches_format" {
  capture
  assert_any_line_matches_format "Deleted %d files"

  capture
  run assert_any_line_matches_format "Deleted %d directories"
  assert_failure
  assert_output_contains "Output has no line matching 'Deleted %d directories'"
  assert_output_contains "match mode: format"

  capture
  run assert_any_line_matches_format "Deleted %z files"
  assert_failure
  assert_output_contains "Unknown format placeholder '%z'."
}

@test "assert_any_line_matches_format_case" {
  capture
  assert_any_line_matches_format_case "Deleted %d files"

  capture
  run assert_any_line_matches_format_case "DELETED %d files"
  assert_failure
  assert_output_contains "case: sensitive"
}

@test "assert_no_line_matches_format" {
  capture
  assert_no_line_matches_format "Deleted %d directories"

  capture
  run assert_no_line_matches_format "Deleted %d files"
  assert_failure
  assert_output_contains "Output has a line matching 'Deleted %d files', but should not"
}

@test "assert_no_line_matches_format_case" {
  capture
  assert_no_line_matches_format_case "DELETED %d files"

  capture
  run assert_no_line_matches_format_case "Deleted %d files"
  assert_failure
  assert_output_contains "Output has a line matching 'Deleted %d files', but should not"
}

##
## Line count assertions.
##

@test "assert_line_count" {
  capture
  assert_line_count 4

  capture
  run assert_line_count 3
  assert_failure
  assert_output_contains "Output has 4 lines, but should have 3"

  # The noun agrees with the count.
  run printf '%s\n' "only one"
  run assert_line_count 2
  assert_failure
  assert_output_contains "Output has 1 line, but should have 2"

  capture
  run assert_line_count "four"
  assert_failure
  assert_output_contains "Line count 'four' is not a non-negative integer."

  capture
  run assert_line_count
  assert_failure
  assert_output_contains "A line count is required."
}

@test "assert_line_count_not" {
  capture
  assert_line_count_not 3

  capture
  run assert_line_count_not 4
  assert_failure
  assert_output_contains "Output has 4 lines, but should not"
}

##
## Line count containment assertions.
##

@test "assert_line_count_contains" {
  capture_counted
  assert_line_count_contains 2 "error"
  assert_line_count_contains 2 "ERROR"
  assert_line_count_contains 0 "absent"

  capture_counted
  run assert_line_count_contains 3 "error"
  assert_failure
  assert_output_contains "Output has 2 lines containing 'error', but should have 3"
  assert_output_contains "match mode: literal"
}

@test "assert_line_count_contains_case" {
  capture_counted
  assert_line_count_contains_case 2 "error"

  capture_counted
  run assert_line_count_contains_case 2 "ERROR"
  assert_failure
  assert_output_contains "Output has 0 lines containing 'ERROR', but should have 2"
  assert_output_contains "note: it matches without the '_case' suffix"
}

@test "assert_line_count_not_contains" {
  capture_counted
  assert_line_count_not_contains 2 "error"

  capture_counted
  run assert_line_count_not_contains 3 "error"
  assert_failure
  assert_output_contains "Output has 2 lines not containing 'error', but should have 3"
}

@test "assert_line_count_not_contains_case" {
  capture_counted
  assert_line_count_not_contains_case 4 "ERROR"

  capture_counted
  run assert_line_count_not_contains_case 2 "ERROR"
  assert_failure
  assert_output_contains "Output has 4 lines not containing 'ERROR', but should have 2"
}

##
## Line count regular expression assertions.
##

@test "assert_line_count_matches" {
  capture_counted
  assert_line_count_matches 2 '^error'

  capture_counted
  run assert_line_count_matches 1 '^error'
  assert_failure
  assert_output_contains "Output has 2 lines matching '^error', but should have 1"
  assert_output_contains "match mode: regex"
}

@test "assert_line_count_matches_case" {
  capture_counted
  assert_line_count_matches_case 2 '^error'

  capture_counted
  run assert_line_count_matches_case 2 '^ERROR'
  assert_failure
  assert_output_contains "Output has 0 lines matching '^ERROR', but should have 2"
}

@test "assert_line_count_not_matches" {
  capture_counted
  assert_line_count_not_matches 2 '^error'

  capture_counted
  run assert_line_count_not_matches 1 '^error'
  assert_failure
  assert_output_contains "Output has 2 lines not matching '^error', but should have 1"
}

@test "assert_line_count_not_matches_case" {
  capture_counted
  assert_line_count_not_matches_case 4 '^ERROR'

  capture_counted
  run assert_line_count_not_matches_case 2 '^ERROR'
  assert_failure
  assert_output_contains "Output has 4 lines not matching '^ERROR', but should have 2"
}

##
## Line count format assertions.
##

@test "assert_line_count_matches_format" {
  capture_formatted
  assert_line_count_matches_format 2 "Deleted %d files"

  capture_formatted
  run assert_line_count_matches_format 1 "Deleted %d files"
  assert_failure
  assert_output_contains "Output has 2 lines matching 'Deleted %d files', but should have 1"
  assert_output_contains "match mode: format"
}

@test "assert_line_count_matches_format_case" {
  capture_formatted_mixed
  assert_line_count_matches_format_case 1 "Deleted %d files"

  capture_formatted_mixed
  run assert_line_count_matches_format_case 2 "Deleted %d files"
  assert_failure
  assert_output_contains "Output has 1 line matching 'Deleted %d files', but should have 2"
}

@test "assert_line_count_not_matches_format" {
  capture_formatted
  assert_line_count_not_matches_format 1 "Deleted %d files"

  capture_formatted
  run assert_line_count_not_matches_format 2 "Deleted %d files"
  assert_failure
  assert_output_contains "Output has 1 line not matching 'Deleted %d files', but should have 2"
}

@test "assert_line_count_not_matches_format_case" {
  capture_formatted_mixed
  assert_line_count_not_matches_format_case 2 "Deleted %d files"

  capture_formatted_mixed
  run assert_line_count_not_matches_format_case 1 "Deleted %d files"
  assert_failure
  assert_output_contains "Output has 2 lines not matching 'Deleted %d files', but should have 1"
}

##
## Matching.
##

@test "line_resolve_index" {
  capture
  run line_resolve_index 0
  assert_success
  assert_output "0"

  capture
  run line_resolve_index 3
  assert_success
  assert_output "3"

  capture
  run line_resolve_index -1
  assert_success
  assert_output "3"

  capture
  run line_resolve_index -4
  assert_success
  assert_output "0"

  # Base 10, so a zero-padded index is not read as octal.
  capture
  run line_resolve_index 010
  assert_failure
  assert_output_contains "Line index 010 is out of range for output with 4 lines."

  capture
  run line_resolve_index 4
  assert_failure
  assert_output_contains "Line index 4 is out of range for output with 4 lines."

  capture
  run line_resolve_index -5
  assert_failure
  assert_output_contains "Line index -5 is out of range for output with 4 lines."

  capture
  run line_resolve_index "two"
  assert_failure
  assert_output_contains "Line index 'two' is not an integer."

  run printf '%s\n' "only one"
  run line_resolve_index 1
  assert_failure
  assert_output_contains "out of range for output with 1 line."
}

@test "line_context" {
  # Clamped at the start.
  capture
  run line_context 0
  assert_success
  assert_output "> 0: Usage: tool.sh
  1: Reading config
  2: Deleted 12 files"

  # Clamped at the end.
  capture
  run line_context 3
  assert_success
  assert_output "  1: Reading config
  2: Deleted 12 files
> 3: Done."

  # A full window either side, with the index padded to the widest one shown so
  # that the mark overwrites the indent instead of shifting the line.
  run printf '%s\n' a b c d e f g h i j k l
  run line_context 10
  assert_success
  assert_output "   8: i
   9: j
> 10: k
  11: l"
}

@test "line_plural" {
  run line_plural 0
  assert_success
  assert_output "0 lines"

  run line_plural 1
  assert_success
  assert_output "1 line"

  run line_plural 2
  assert_success
  assert_output "2 lines"
}

@test "line_participle" {
  run line_participle "literal" 0
  assert_success
  assert_output "containing"

  run line_participle "regex" 0
  assert_success
  assert_output "matching"

  run line_participle "format" 0
  assert_success
  assert_output "matching"

  run line_participle "literal" 1
  assert_success
  assert_output "not containing"
}

@test "line_match_indices" {
  capture_counted
  run line_match_indices 0 "literal" 0 "error"
  assert_success
  assert_output "0 2"

  capture_counted
  run line_match_indices 1 "literal" 0 "error"
  assert_success
  assert_output "1 3"

  capture_counted
  run line_match_indices 0 "literal" 0 "absent"
  assert_success
  assert_output ""

  # Checked even when there is no line to try it against.
  run printf ''
  run line_match_indices 0 "regex" 0 "["
  assert_failure
  assert_output_contains "Invalid regular expression '['."
}

@test "line_equal_indices" {
  capture_counted
  run line_equal_indices "ok"
  assert_success
  assert_output "1 3"

  capture_counted
  run line_equal_indices "absent"
  assert_success
  assert_output ""
}

@test "line_assert_index_match" {
  capture
  run assert_line_contains 1
  assert_failure
  assert_output_contains "A line index and a needle are required."

  capture
  run assert_line_matches 1 "["
  assert_failure
  assert_output_contains "Invalid regular expression '['."
}

@test "line_assert_index_equal" {
  capture
  run line_assert_index_equal 1
  assert_failure
  assert_output_contains "A line index and a string are required."
}

@test "line_assert_any_match" {
  capture
  run line_assert_any_match 1 "literal" 0
  assert_failure
  assert_output_contains "A needle is required."
}

@test "line_assert_any_equal" {
  capture
  run line_assert_any_equal 1
  assert_failure
  assert_output_contains "A string is required."
}

@test "line_assert_count_match" {
  capture_counted
  run line_assert_count_match 0 "literal" 0 2
  assert_failure
  assert_output_contains "A line count and a needle are required."

  capture_counted
  run assert_line_count_contains "two" "error"
  assert_failure
  assert_output_contains "Line count 'two' is not a non-negative integer."
}

##
## Empty lines.
##

@test "Empty lines are dropped unless the runner is asked to keep them" {
  # Without the option, an empty line is not an element and the indices of
  # everything after it shift up.
  run printf '%s\n' "first" "" "third"
  assert_line_count 2
  assert_line 1 "third"

  run --keep-empty-lines printf '%s\n' "first" "" "third"
  assert_line_count 3
  assert_line 1 ""
  assert_line 2 "third"
}
