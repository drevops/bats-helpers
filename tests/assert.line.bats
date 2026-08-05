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
  assert_output_contains "-- Line does not equal string --
line (1 line):
0
expected (1 line):
Reading config
actual (1 line):
Usage: tool.sh
context (3 lines):
> 0: Usage: tool.sh
  1: Reading config
  2: Deleted 12 files
--"

  # The line reached through a negative index is named both ways.
  capture
  run assert_line -1 "Usage: tool.sh"
  assert_failure
  assert_output_contains "-- Line does not equal string --"
  assert_output_contains "line (1 line):
3 (from index -1)"

  # An index outside the captured lines is an error rather than a comparison
  # against an empty string, at either end.
  capture
  run assert_line 4 "Done."
  assert_failure
  assert_output_contains "Line index '4' is out of range for output with 4 lines."

  capture
  run assert_line -5 "Usage: tool.sh"
  assert_failure
  assert_output_contains "Line index '-5' is out of range for output with 4 lines."
}

@test "assert_line_not" {
  capture
  assert_line_not 0 "Reading config"
  assert_line_not -1 "Usage: tool.sh"

  capture
  run assert_line_not 0 "Usage: tool.sh"
  assert_failure
  assert_output_contains "-- Line equals string, but should not --
line (1 line):
0
string (1 line):
Usage: tool.sh"
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
  assert_output_contains "-- Line does not contain substring --
line (1 line):
1
substring (1 line):
absent
match mode (1 line):
literal
case (1 line):
insensitive
context (4 lines):
  0: Usage: tool.sh
> 1: Reading config
  2: Deleted 12 files
  3: Done.
--"

  capture
  run assert_line_contains 9 "config"
  assert_failure
  assert_output_contains "Line index '9' is out of range for output with 4 lines."
}

@test "assert_line_contains_case" {
  capture
  assert_line_contains_case 1 "config"

  capture
  run assert_line_contains_case 1 "CONFIG"
  assert_failure
  assert_output_contains "-- Line does not contain substring --"
  assert_output_contains "case (1 line):
sensitive"
  assert_output_contains "note (1 line):
it matches without the '_case' suffix"
}

@test "assert_line_not_contains" {
  capture
  assert_line_not_contains 1 "absent"

  capture
  run assert_line_not_contains 1 "config"
  assert_failure
  assert_output_contains "-- Line contains substring, but should not --"

  capture
  run assert_line_not_contains 1 "CONFIG"
  assert_failure
  assert_output_contains "-- Line contains substring, but should not --"
}

@test "assert_line_not_contains_case" {
  capture
  assert_line_not_contains_case 1 "CONFIG"
  assert_line_not_contains_case 1 "absent"

  capture
  run assert_line_not_contains_case 1 "config"
  assert_failure
  assert_output_contains "-- Line contains substring, but should not --"
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
  assert_output_contains "-- Line does not match regular expression --"
  assert_output_contains "regular expression (1 line):
Deleted [a-z]+ files"
  assert_output_contains "match mode (1 line):
regex"
  assert_output_contains "> 2: Deleted 12 files"
}

@test "assert_line_matches_case" {
  capture
  assert_line_matches_case 2 'Deleted [0-9]+ files'

  capture
  run assert_line_matches_case 2 'DELETED [0-9]+ files'
  assert_failure
  assert_output_contains "case (1 line):
sensitive"
  assert_output_contains "note (1 line):
it matches without the '_case' suffix"
}

@test "assert_line_not_matches" {
  capture
  assert_line_not_matches 2 'Deleted [a-z]+ files'

  capture
  run assert_line_not_matches 2 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "-- Line matches regular expression, but should not --"
}

@test "assert_line_not_matches_case" {
  capture
  assert_line_not_matches_case 2 'DELETED [0-9]+ files'

  capture
  run assert_line_not_matches_case 2 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "-- Line matches regular expression, but should not --"
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
  assert_output_contains "-- Line does not match format --"
  assert_output_contains "format (1 line):
Deleted %d directories"
  assert_output_contains "match mode (1 line):
format"

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
  assert_output_contains "case (1 line):
sensitive"
}

@test "assert_line_not_matches_format" {
  capture
  assert_line_not_matches_format 2 "Deleted %d directories"

  capture
  run assert_line_not_matches_format 2 "Deleted %d files"
  assert_failure
  assert_output_contains "-- Line matches format, but should not --"
}

@test "assert_line_not_matches_format_case" {
  capture
  assert_line_not_matches_format_case 2 "DELETED %d files"

  capture
  run assert_line_not_matches_format_case 2 "Deleted %d files"
  assert_failure
  assert_output_contains "-- Line matches format, but should not --"
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
  assert_output_contains "-- Output has no line equal to string --
string : absent
--"
}

@test "assert_no_line" {
  capture
  assert_no_line "absent"

  # An exact comparison, so a line that merely contains it does not count.
  assert_no_line "Done"

  capture
  run assert_no_line "Done."
  assert_failure
  assert_output_contains "-- Output has a line equal to string, but should not --
string (1 line):
Done.
context (3 lines):
  1: Reading config
  2: Deleted 12 files
> 3: Done.
--"
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
  assert_output_contains "-- Output has no line containing substring --
substring  : absent
match mode : literal
case       : insensitive
--"
}

@test "assert_any_line_contains_case" {
  capture
  assert_any_line_contains_case "config"

  capture
  run assert_any_line_contains_case "CONFIG"
  assert_failure
  assert_output_contains "-- Output has no line containing substring --"
  assert_output_contains "case       : sensitive"
  assert_output_contains "note       : it matches without the '_case' suffix"
}

@test "assert_no_line_contains" {
  capture
  assert_no_line_contains "absent"

  capture
  run assert_no_line_contains "config"
  assert_failure
  assert_output_contains "-- Output has a line containing substring, but should not --"
  assert_output_contains "> 1: Reading config"

  # Only the case setting let this one through, so it is named.
  capture
  run assert_no_line_contains "CONFIG"
  assert_failure
  assert_output_contains "note (1 line):
it does not match with the '_case' suffix"
}

@test "assert_no_line_contains_case" {
  capture
  assert_no_line_contains_case "CONFIG"

  capture
  run assert_no_line_contains_case "config"
  assert_failure
  assert_output_contains "-- Output has a line containing substring, but should not --"
  assert_output_contains "case (1 line):
sensitive"
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
  assert_output_contains "-- Output has no line matching regular expression --
regular expression : Deleted [a-z]+ files
match mode         : regex
case               : insensitive
--"

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
  assert_output_contains "case               : sensitive"
}

@test "assert_no_line_matches" {
  capture
  assert_no_line_matches 'Deleted [a-z]+ files'

  capture
  run assert_no_line_matches 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "-- Output has a line matching regular expression, but should not --"
  assert_output_contains "> 2: Deleted 12 files"
}

@test "assert_no_line_matches_case" {
  capture
  assert_no_line_matches_case 'DELETED [0-9]+ files'

  capture
  run assert_no_line_matches_case 'Deleted [0-9]+ files'
  assert_failure
  assert_output_contains "-- Output has a line matching regular expression, but should not --"
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
  assert_output_contains "-- Output has no line matching format --
format     : Deleted %d directories
match mode : format
case       : insensitive
--"

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
  assert_output_contains "case       : sensitive"
}

@test "assert_no_line_matches_format" {
  capture
  assert_no_line_matches_format "Deleted %d directories"

  capture
  run assert_no_line_matches_format "Deleted %d files"
  assert_failure
  assert_output_contains "-- Output has a line matching format, but should not --"
}

@test "assert_no_line_matches_format_case" {
  capture
  assert_no_line_matches_format_case "DELETED %d files"

  capture
  run assert_no_line_matches_format_case "Deleted %d files"
  assert_failure
  assert_output_contains "-- Output has a line matching format, but should not --"
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
  assert_output_contains "-- Output does not have the expected number of lines --
expected : 3
actual   : 4
--"

  run printf '%s\n' "only one"
  run assert_line_count 2
  assert_failure
  assert_output_contains "expected : 2
actual   : 1"

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
  assert_output_contains "-- Output has the given number of lines, but should not --
line count : 4
--"
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
  assert_output_contains "-- Output does not have the expected number of lines containing substring --
substring  : error
match mode : literal
case       : insensitive
expected   : 3
actual     : 2
--"
}

@test "assert_line_count_contains_case" {
  capture_counted
  assert_line_count_contains_case 2 "error"

  capture_counted
  run assert_line_count_contains_case 2 "ERROR"
  assert_failure
  assert_output_contains "expected   : 2
actual     : 0"
  assert_output_contains "note       : it matches without the '_case' suffix"
}

@test "assert_line_count_not_contains" {
  capture_counted
  assert_line_count_not_contains 2 "error"

  capture_counted
  run assert_line_count_not_contains 3 "error"
  assert_failure
  assert_output_contains "-- Output does not have the expected number of lines not containing substring --"
  assert_output_contains "expected   : 3
actual     : 2"
}

@test "assert_line_count_not_contains_case" {
  capture_counted
  assert_line_count_not_contains_case 4 "ERROR"

  capture_counted
  run assert_line_count_not_contains_case 2 "ERROR"
  assert_failure
  assert_output_contains "-- Output does not have the expected number of lines not containing substring --"
  assert_output_contains "expected   : 2
actual     : 4"
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
  assert_output_contains "-- Output does not have the expected number of lines matching regular expression --
regular expression : ^error
match mode         : regex
case               : insensitive
expected           : 1
actual             : 2
--"
}

@test "assert_line_count_matches_case" {
  capture_counted
  assert_line_count_matches_case 2 '^error'

  capture_counted
  run assert_line_count_matches_case 2 '^ERROR'
  assert_failure
  assert_output_contains "expected           : 2
actual             : 0"
}

@test "assert_line_count_not_matches" {
  capture_counted
  assert_line_count_not_matches 2 '^error'

  capture_counted
  run assert_line_count_not_matches 1 '^error'
  assert_failure
  assert_output_contains "-- Output does not have the expected number of lines not matching regular expression --"
  assert_output_contains "expected           : 1
actual             : 2"
}

@test "assert_line_count_not_matches_case" {
  capture_counted
  assert_line_count_not_matches_case 4 '^ERROR'

  capture_counted
  run assert_line_count_not_matches_case 2 '^ERROR'
  assert_failure
  assert_output_contains "-- Output does not have the expected number of lines not matching regular expression --"
  assert_output_contains "expected           : 2
actual             : 4"
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
  assert_output_contains "-- Output does not have the expected number of lines matching format --
format     : Deleted %d files
match mode : format
case       : insensitive
expected   : 1
actual     : 2
--"
}

@test "assert_line_count_matches_format_case" {
  capture_formatted_mixed
  assert_line_count_matches_format_case 1 "Deleted %d files"

  capture_formatted_mixed
  run assert_line_count_matches_format_case 2 "Deleted %d files"
  assert_failure
  assert_output_contains "expected   : 2
actual     : 1"
}

@test "assert_line_count_not_matches_format" {
  capture_formatted
  assert_line_count_not_matches_format 1 "Deleted %d files"

  capture_formatted
  run assert_line_count_not_matches_format 2 "Deleted %d files"
  assert_failure
  assert_output_contains "-- Output does not have the expected number of lines not matching format --"
  assert_output_contains "expected   : 2
actual     : 1"
}

@test "assert_line_count_not_matches_format_case" {
  capture_formatted_mixed
  assert_line_count_not_matches_format_case 2 "Deleted %d files"

  capture_formatted_mixed
  run assert_line_count_not_matches_format_case 1 "Deleted %d files"
  assert_failure
  assert_output_contains "-- Output does not have the expected number of lines not matching format --"
  assert_output_contains "expected   : 1
actual     : 2"
  assert_output_contains "note       : it matches without the '_case' suffix"
}

##
## Matching.
##

@test "_line_resolve_index" {
  capture
  run _line_resolve_index 0
  assert_success
  assert_output "0"

  capture
  run _line_resolve_index 3
  assert_success
  assert_output "3"

  capture
  run _line_resolve_index -1
  assert_success
  assert_output "3"

  capture
  run _line_resolve_index -4
  assert_success
  assert_output "0"

  # Base 10, so a zero-padded index is not read as octal.
  capture
  run _line_resolve_index 010
  assert_failure
  assert_output_contains "Line index '010' is out of range for output with 4 lines."

  capture
  run _line_resolve_index 4
  assert_failure
  assert_output_contains "Line index '4' is out of range for output with 4 lines."

  capture
  run _line_resolve_index -5
  assert_failure
  assert_output_contains "Line index '-5' is out of range for output with 4 lines."

  capture
  run _line_resolve_index "two"
  assert_failure
  assert_output_contains "Line index 'two' is not an integer."

  run printf '%s\n' "only one"
  run _line_resolve_index 1
  assert_failure
  assert_output_contains "out of range for output with 1 line."
}

@test "_line_context" {
  # Clamped at the start.
  capture
  run _line_context 0
  assert_success
  assert_output "> 0: Usage: tool.sh
  1: Reading config
  2: Deleted 12 files"

  # Clamped at the end.
  capture
  run _line_context 3
  assert_success
  assert_output "  1: Reading config
  2: Deleted 12 files
> 3: Done."

  # A full window either side, with the index padded to the widest one shown so
  # that the mark overwrites the indent instead of shifting the line.
  run printf '%s\n' a b c d e f g h i j k l
  run _line_context 10
  assert_success
  assert_output "   8: i
   9: j
> 10: k
  11: l"
}

@test "_line_participle" {
  run _line_participle "literal" 0
  assert_success
  assert_output "containing"

  run _line_participle "regex" 0
  assert_success
  assert_output "matching"

  run _line_participle "format" 0
  assert_success
  assert_output "matching"

  run _line_participle "literal" 1
  assert_success
  assert_output "not containing"
}

@test "_line_match_indices" {
  capture_counted
  run _line_match_indices 0 "literal" 0 "error"
  assert_success
  assert_output "0 2"

  capture_counted
  run _line_match_indices 1 "literal" 0 "error"
  assert_success
  assert_output "1 3"

  capture_counted
  run _line_match_indices 0 "literal" 0 "absent"
  assert_success
  assert_output ""

  # Checked even when there is no line to try it against.
  run printf ''
  run _line_match_indices 0 "regex" 0 "["
  assert_failure
  assert_output_contains "Invalid regular expression '['."
}

@test "_line_equal_indices" {
  capture_counted
  run _line_equal_indices "ok"
  assert_success
  assert_output "1 3"

  capture_counted
  run _line_equal_indices "absent"
  assert_success
  assert_output ""
}

@test "_line_assert_index_match" {
  capture
  run assert_line_contains 1
  assert_failure
  assert_output_contains "A line index and a needle are required."

  capture
  run assert_line_matches 1 "["
  assert_failure
  assert_output_contains "Invalid regular expression '['."
}

@test "_line_assert_index_equal" {
  capture
  run _line_assert_index_equal 1
  assert_failure
  assert_output_contains "A line index and a string are required."
}

@test "_line_assert_any_match" {
  capture
  run _line_assert_any_match 1 "literal" 0
  assert_failure
  assert_output_contains "A needle is required."
}

@test "_line_assert_any_equal" {
  capture
  run _line_assert_any_equal 1
  assert_failure
  assert_output_contains "A string is required."
}

@test "_line_assert_count_match" {
  capture_counted
  run _line_assert_count_match 0 "literal" 0 2
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
