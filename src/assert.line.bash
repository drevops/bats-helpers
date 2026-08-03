#!/usr/bin/env bash
##
# @file
# Assertions for the individual lines of a captured stream.
#
# shellcheck disable=SC2154

##
## Line assertions.
##

##
# Asserts that the line at an index equals a string.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line() {
  line_assert_index_equal 0 "$@"
}

##
# Asserts that the line at an index does not equal a string.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not() {
  line_assert_index_equal 1 "$@"
}

##
## Line containment assertions.
##

##
# Asserts that the line at an index contains a string, ignoring case.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_contains() {
  line_assert_index_match 0 "literal" 0 "$@"
}

##
# Asserts that the line at an index contains a string, case-sensitively.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_contains_case() {
  line_assert_index_match 0 "literal" 1 "$@"
}

##
# Asserts that the line at an index does not contain a string, ignoring case.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not_contains() {
  line_assert_index_match 1 "literal" 0 "$@"
}

##
# Asserts that the line at an index does not contain a string,
# case-sensitively.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not_contains_case() {
  line_assert_index_match 1 "literal" 1 "$@"
}

##
## Line regular expression assertions.
##

##
# Asserts that the line at an index matches a regular expression, ignoring
# case.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_matches() {
  line_assert_index_match 0 "regex" 0 "$@"
}

##
# Asserts that the line at an index matches a regular expression,
# case-sensitively.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_matches_case() {
  line_assert_index_match 0 "regex" 1 "$@"
}

##
# Asserts that the line at an index does not match a regular expression,
# ignoring case.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not_matches() {
  line_assert_index_match 1 "regex" 0 "$@"
}

##
# Asserts that the line at an index does not match a regular expression,
# case-sensitively.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not_matches_case() {
  line_assert_index_match 1 "regex" 1 "$@"
}

##
## Line format assertions.
##

##
# Asserts that the line at an index matches a format string, ignoring case.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_matches_format() {
  line_assert_index_match 0 "format" 0 "$@"
}

##
# Asserts that the line at an index matches a format string, case-sensitively.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_matches_format_case() {
  line_assert_index_match 0 "format" 1 "$@"
}

##
# Asserts that the line at an index does not match a format string, ignoring
# case.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not_matches_format() {
  line_assert_index_match 1 "format" 0 "$@"
}

##
# Asserts that the line at an index does not match a format string,
# case-sensitively.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_not_matches_format_case() {
  line_assert_index_match 1 "format" 1 "$@"
}

##
## Any line assertions.
##

##
# Asserts that some line equals a string.
#
# Arguments:
#   1. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line() {
  line_assert_any_equal 1 "$@"
}

##
# Asserts that no line equals a string.
#
# Arguments:
#   1. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line() {
  line_assert_any_equal 0 "$@"
}

##
## Any line containment assertions.
##

##
# Asserts that some line contains a string, ignoring case.
#
# Arguments:
#   1. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line_contains() {
  line_assert_any_match 1 "literal" 0 "$@"
}

##
# Asserts that some line contains a string, case-sensitively.
#
# Arguments:
#   1. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line_contains_case() {
  line_assert_any_match 1 "literal" 1 "$@"
}

##
# Asserts that no line contains a string, ignoring case.
#
# Arguments:
#   1. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line_contains() {
  line_assert_any_match 0 "literal" 0 "$@"
}

##
# Asserts that no line contains a string, case-sensitively.
#
# Arguments:
#   1. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line_contains_case() {
  line_assert_any_match 0 "literal" 1 "$@"
}

##
## Any line regular expression assertions.
##

##
# Asserts that some line matches a regular expression, ignoring case.
#
# Arguments:
#   1. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line_matches() {
  line_assert_any_match 1 "regex" 0 "$@"
}

##
# Asserts that some line matches a regular expression, case-sensitively.
#
# Arguments:
#   1. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line_matches_case() {
  line_assert_any_match 1 "regex" 1 "$@"
}

##
# Asserts that no line matches a regular expression, ignoring case.
#
# Arguments:
#   1. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line_matches() {
  line_assert_any_match 0 "regex" 0 "$@"
}

##
# Asserts that no line matches a regular expression, case-sensitively.
#
# Arguments:
#   1. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line_matches_case() {
  line_assert_any_match 0 "regex" 1 "$@"
}

##
## Any line format assertions.
##

##
# Asserts that some line matches a format string, ignoring case.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line_matches_format() {
  line_assert_any_match 1 "format" 0 "$@"
}

##
# Asserts that some line matches a format string, case-sensitively.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_any_line_matches_format_case() {
  line_assert_any_match 1 "format" 1 "$@"
}

##
# Asserts that no line matches a format string, ignoring case.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line_matches_format() {
  line_assert_any_match 0 "format" 0 "$@"
}

##
# Asserts that no line matches a format string, case-sensitively.
#
# Arguments:
#   1. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_no_line_matches_format_case() {
  line_assert_any_match 0 "format" 1 "$@"
}

##
## Line count assertions.
##

##
# Asserts the number of captured lines.
#
# Arguments:
#   1. expected: Number of lines to expect.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count() {
  line_assert_count 0 "$@"
}

##
# Asserts that the number of captured lines is not a number.
#
# Arguments:
#   1. expected: Number of lines not to expect.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not() {
  line_assert_count 1 "$@"
}

##
## Line count containment assertions.
##

##
# Asserts how many lines contain a string, ignoring case.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_contains() {
  line_assert_count_match 0 "literal" 0 "$@"
}

##
# Asserts how many lines contain a string, case-sensitively.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_contains_case() {
  line_assert_count_match 0 "literal" 1 "$@"
}

##
# Asserts how many lines do not contain a string, ignoring case.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not_contains() {
  line_assert_count_match 1 "literal" 0 "$@"
}

##
# Asserts how many lines do not contain a string, case-sensitively.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not_contains_case() {
  line_assert_count_match 1 "literal" 1 "$@"
}

##
## Line count regular expression assertions.
##

##
# Asserts how many lines match a regular expression, ignoring case.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_matches() {
  line_assert_count_match 0 "regex" 0 "$@"
}

##
# Asserts how many lines match a regular expression, case-sensitively.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_matches_case() {
  line_assert_count_match 0 "regex" 1 "$@"
}

##
# Asserts how many lines do not match a regular expression, ignoring case.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not_matches() {
  line_assert_count_match 1 "regex" 0 "$@"
}

##
# Asserts how many lines do not match a regular expression, case-sensitively.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Extended regular expression to match.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not_matches_case() {
  line_assert_count_match 1 "regex" 1 "$@"
}

##
## Line count format assertions.
##

##
# Asserts how many lines match a format string, ignoring case.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_matches_format() {
  line_assert_count_match 0 "format" 0 "$@"
}

##
# Asserts how many lines match a format string, case-sensitively.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_matches_format_case() {
  line_assert_count_match 0 "format" 1 "$@"
}

##
# Asserts how many lines do not match a format string, ignoring case.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not_matches_format() {
  line_assert_count_match 1 "format" 0 "$@"
}

##
# Asserts how many lines do not match a format string, case-sensitively.
#
# Arguments:
#   1. expected: Number of lines to expect.
#   2. needle: Format string, see 'string_format_to_regex'.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
assert_line_count_not_matches_format_case() {
  line_assert_count_match 1 "format" 1 "$@"
}

##
## Matching.
##

##
# Resolves a line index into an offset into the captured lines.
#
# Arguments:
#   1. index: Line index. A negative value counts back from the last line, so
#      '-1' is the last one.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
#
# Outputs:
#   STDOUT: The resolved offset.
##
line_resolve_index() {
  local index="${1-}"

  if ! [[ ${index} =~ ^-?[0-9]+$ ]]; then
    flunk "Line index '${index}' is not an integer."
    return 1
  fi

  local total="${#lines[@]}"
  local resolved

  # Base 10 is explicit so that a zero-padded index is not read as octal.
  if [ "${index:0:1}" = "-" ]; then
    resolved=$((total - 10#${index#-}))
  else
    resolved=$((10#${index}))
  fi

  # An out-of-range index would otherwise compare against an empty string,
  # which reads as an ordinary mismatch and hides where the fault is.
  if [ "${resolved}" -lt 0 ] || [ "${resolved}" -ge "${total}" ]; then
    flunk "Line index ${index} is out of range for output with $(line_plural "${total}")."
    return 1
  fi

  printf '%s\n' "${resolved}"
}

##
# Names a line by the offset it sits at and the index it was reached through.
#
# Arguments:
#   1. index: Index as it was given.
#   2. resolved: Offset the index resolved to.
#
# Outputs:
#   STDOUT: The label.
##
line_label() {
  if [ "${1}" = "${2}" ]; then
    printf 'Line %s\n' "${2}"
    return 0
  fi

  printf 'Line %s (from index %s)\n' "${2}" "${1}"
}

##
# Prints the lines around one line, with that line marked.
#
# The mark overwrites the indent instead of being inserted, so every line stays
# in the same column and the marked one can still be read against its
# neighbours.
#
# Arguments:
#   1. index: Offset of the line to mark.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
#
# Outputs:
#   STDOUT: The window of lines, one per line.
##
line_context() {
  local index="${1}"
  local total="${#lines[@]}"
  local window=2

  local first=$((index - window))
  local last=$((index + window))

  [ "${first}" -lt 0 ] && first=0
  [ "${last}" -gt $((total - 1)) ] && last=$((total - 1))

  local width="${#last}"
  local i
  local marker

  for ((i = first; i <= last; i++)); do
    marker="  "
    [ "${i}" -eq "${index}" ] && marker="> "
    printf '%s%*d: %s\n' "${marker}" "${width}" "${i}" "${lines[i]}"
  done
}

##
# Names a number of lines.
#
# Arguments:
#   1. count: Number of lines.
#
# Outputs:
#   STDOUT: The count and the noun agreeing with it.
##
line_plural() {
  if [ "${1}" -eq 1 ]; then
    printf '1 line\n'
    return 0
  fi

  printf '%s lines\n' "${1}"
}

##
# Names how a needle is read, as a participle for a failure report.
#
# Arguments:
#   1. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   2. negate: '1' when the report is about the lines that do not match.
#
# Outputs:
#   STDOUT: The participle.
##
line_participle() {
  local participle="containing"
  [ "${1}" != "literal" ] && participle="matching"

  if [ "${2}" = "1" ]; then
    printf 'not %s\n' "${participle}"
    return 0
  fi

  printf '%s\n' "${participle}"
}

##
# Validates a value given as a number of lines.
#
# Arguments:
#   1. count: Value to validate.
##
line_validate_count() {
  if ! [[ ${1-} =~ ^[0-9]+$ ]]; then
    flunk "Line count '${1-}' is not a non-negative integer."
    return 1
  fi
}

##
# Lists the offsets of the lines a needle matches.
#
# Arguments:
#   1. negate: '1' to list the lines the needle does not match.
#   2. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   3. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   4. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
#
# Outputs:
#   STDOUT: The matching offsets, separated by spaces.
##
line_match_indices() {
  local negate="${1}"
  local mode="${2}"
  local case_sensitive="${3}"
  local needle="${4}"

  local pattern="${needle}"
  local pattern_mode="${mode}"

  if [ "${mode}" = "format" ]; then
    pattern="$(string_format_to_regex "${needle}")" || return 1
    pattern_mode="regex"
  fi

  # Checked once against an empty string, so that an unusable expression is
  # reported even when there is no line for it to be tried against.
  local match_status=0
  string_match "" "${pattern}" "${pattern_mode}" "${case_sensitive}" "anywhere" || match_status=$?

  if [ "${match_status}" -eq 2 ]; then
    flunk "Invalid regular expression '${needle}'."
    return 1
  fi

  local total="${#lines[@]}"
  local matched=""
  local i

  for ((i = 0; i < total; i++)); do
    match_status=0
    string_match "${lines[i]}" "${pattern}" "${pattern_mode}" "${case_sensitive}" "anywhere" || match_status=$?

    if [ "${negate}" = "1" ]; then
      [ "${match_status}" -ne 0 ] && matched="${matched}${matched:+ }${i}"
    else
      [ "${match_status}" -eq 0 ] && matched="${matched}${matched:+ }${i}"
    fi
  done

  printf '%s\n' "${matched}"
}

##
# Lists the offsets of the lines equal to a string.
#
# Arguments:
#   1. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
#
# Outputs:
#   STDOUT: The matching offsets, separated by spaces.
##
line_equal_indices() {
  local expected="${1}"
  local total="${#lines[@]}"
  local matched=""
  local i

  for ((i = 0; i < total; i++)); do
    [ "${lines[i]}" = "${expected}" ] && matched="${matched}${matched:+ }${i}"
  done

  printf '%s\n' "${matched}"
}

##
# Asserts that a needle matches the line at an index, reporting how on failure.
#
# Arguments:
#   1. negate: '1' to assert that the needle does not match.
#   2. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   3. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   4. index: Line index. A negative value counts back from the last line.
#   5. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
line_assert_index_match() {
  if [ "$#" -ne 5 ]; then
    flunk "A line index and a needle are required."
    return 1
  fi

  local negate="${1}"
  local mode="${2}"
  local case_sensitive="${3}"
  local given="${4}"
  local needle="${5}"

  local index
  index="$(line_resolve_index "${given}")" || return 1

  local haystack="${lines[index]}"

  local pattern="${needle}"
  local pattern_mode="${mode}"

  if [ "${mode}" = "format" ]; then
    pattern="$(string_format_to_regex "${needle}")" || return 1
    pattern_mode="regex"
  fi

  local match_status=0
  string_match "${haystack}" "${pattern}" "${pattern_mode}" "${case_sensitive}" "anywhere" || match_status=$?

  if [ "${match_status}" -eq 2 ]; then
    flunk "Invalid regular expression '${needle}'."
    return 1
  fi

  if [ "${negate}" = "1" ]; then
    [ "${match_status}" -ne 0 ] && return 0
  else
    [ "${match_status}" -eq 0 ] && return 0
  fi

  local verb="contain"
  local verb_third_person="contains"

  if [ "${mode}" != "literal" ]; then
    verb="match"
    verb_third_person="matches"
  fi

  local message
  if [ "${negate}" = "1" ]; then
    message="$(line_label "${given}" "${index}") ${verb_third_person} '${needle}', but should not"
  else
    message="$(line_label "${given}" "${index}") does not ${verb} '${needle}'"
  fi

  local opposite_status=0
  string_match "${haystack}" "${pattern}" "${pattern_mode}" $((1 - case_sensitive)) "anywhere" || opposite_status=$?

  local case_decided=0
  [ "${opposite_status}" -ne "${match_status}" ] && case_decided=1

  message="${message}"$'\n'"$(string_match_footer "${mode}" "${case_sensitive}" "${case_decided}")"
  message="${message}"$'\n\n'"$(line_context "${index}")"

  format_error "${message}" | flunk
}

##
# Asserts that the line at an index equals a string, reporting it on failure.
#
# Arguments:
#   1. negate: '1' to assert that the line does not equal the string.
#   2. index: Line index. A negative value counts back from the last line.
#   3. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
line_assert_index_equal() {
  if [ "$#" -ne 3 ]; then
    flunk "A line index and a string are required."
    return 1
  fi

  local negate="${1}"
  local given="${2}"
  local expected="${3}"

  local index
  index="$(line_resolve_index "${given}")" || return 1

  local equal=0
  [ "${lines[index]}" = "${expected}" ] || equal=1

  if [ "${negate}" = "1" ]; then
    [ "${equal}" -ne 0 ] && return 0
  else
    [ "${equal}" -eq 0 ] && return 0
  fi

  local message
  if [ "${negate}" = "1" ]; then
    message="$(line_label "${given}" "${index}") equals '${expected}', but should not"
  else
    message="$(line_label "${given}" "${index}") does not equal '${expected}'"
  fi

  message="${message}"$'\n\n'"$(line_context "${index}")"

  format_error "${message}" | flunk
}

##
# Asserts that some or no line matches a needle, reporting how on failure.
#
# Arguments:
#   1. present: '1' to assert that some line matches, '0' that none does.
#   2. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   3. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   4. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
line_assert_any_match() {
  if [ "$#" -ne 4 ]; then
    flunk "A needle is required."
    return 1
  fi

  local present="${1}"
  local mode="${2}"
  local case_sensitive="${3}"
  local needle="${4}"

  local matched
  matched="$(line_match_indices 0 "${mode}" "${case_sensitive}" "${needle}")" || return 1

  # shellcheck disable=SC2206
  local -a indices=(${matched})

  if [ "${present}" = "1" ]; then
    [ "${#indices[@]}" -gt 0 ] && return 0
  else
    [ "${#indices[@]}" -eq 0 ] && return 0
  fi

  local opposite
  opposite="$(line_match_indices 0 "${mode}" $((1 - case_sensitive)) "${needle}")" || return 1

  # shellcheck disable=SC2206
  local -a opposite_indices=(${opposite})

  local case_decided=0
  if [ "${present}" = "1" ]; then
    [ "${#opposite_indices[@]}" -gt 0 ] && case_decided=1
  else
    [ "${#opposite_indices[@]}" -eq 0 ] && case_decided=1
  fi

  local participle
  participle="$(line_participle "${mode}" 0)"

  local message
  if [ "${present}" = "1" ]; then
    message="Output has no line ${participle} '${needle}'"
  else
    message="Output has a line ${participle} '${needle}', but should not"
  fi

  message="${message}"$'\n'"$(string_match_footer "${mode}" "${case_sensitive}" "${case_decided}")"

  if [ "${#indices[@]}" -gt 0 ]; then
    message="${message}"$'\n\n'"$(line_context "${indices[0]}")"
  fi

  format_error "${message}" | flunk
}

##
# Asserts that some or no line equals a string, reporting it on failure.
#
# Arguments:
#   1. present: '1' to assert that some line equals it, '0' that none does.
#   2. expected: String to compare against.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
line_assert_any_equal() {
  if [ "$#" -ne 2 ]; then
    flunk "A string is required."
    return 1
  fi

  local present="${1}"
  local expected="${2}"

  local matched
  matched="$(line_equal_indices "${expected}")"

  # shellcheck disable=SC2206
  local -a indices=(${matched})

  if [ "${present}" = "1" ]; then
    [ "${#indices[@]}" -gt 0 ] && return 0
  else
    [ "${#indices[@]}" -eq 0 ] && return 0
  fi

  local message
  if [ "${present}" = "1" ]; then
    message="Output has no line equal to '${expected}'"
  else
    message="Output has a line equal to '${expected}', but should not"
  fi

  if [ "${#indices[@]}" -gt 0 ]; then
    message="${message}"$'\n\n'"$(line_context "${indices[0]}")"
  fi

  format_error "${message}" | flunk
}

##
# Asserts the number of captured lines, reporting the tally on failure.
#
# Arguments:
#   1. negate: '1' to assert that the number differs.
#   2. expected: Number of lines to expect.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
line_assert_count() {
  if [ "$#" -ne 2 ]; then
    flunk "A line count is required."
    return 1
  fi

  local negate="${1}"
  local expected="${2}"

  line_validate_count "${expected}" || return 1

  local total="${#lines[@]}"

  if [ "${negate}" = "1" ]; then
    [ "${total}" -ne "${expected}" ] && return 0

    format_error "Output has $(line_plural "${total}"), but should not" | flunk
    return 1
  fi

  [ "${total}" -eq "${expected}" ] && return 0

  format_error "Output has $(line_plural "${total}"), but should have ${expected}" | flunk
}

##
# Asserts how many lines a needle matches, reporting the tally on failure.
#
# Arguments:
#   1. negate: '1' to count the lines the needle does not match.
#   2. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   3. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   4. expected: Number of lines to expect.
#   5. needle: String to search for.
#
# Globals:
#   lines: Lines captured by the last 'run' call.
##
line_assert_count_match() {
  if [ "$#" -ne 5 ]; then
    flunk "A line count and a needle are required."
    return 1
  fi

  local negate="${1}"
  local mode="${2}"
  local case_sensitive="${3}"
  local expected="${4}"
  local needle="${5}"

  line_validate_count "${expected}" || return 1

  local matched
  matched="$(line_match_indices "${negate}" "${mode}" "${case_sensitive}" "${needle}")" || return 1

  # shellcheck disable=SC2206
  local -a indices=(${matched})
  local actual="${#indices[@]}"

  [ "${actual}" -eq "${expected}" ] && return 0

  local opposite
  opposite="$(line_match_indices "${negate}" "${mode}" $((1 - case_sensitive)) "${needle}")" || return 1

  # shellcheck disable=SC2206
  local -a opposite_indices=(${opposite})

  local case_decided=0
  [ "${#opposite_indices[@]}" -eq "${expected}" ] && case_decided=1

  local participle
  participle="$(line_participle "${mode}" "${negate}")"

  local message="Output has $(line_plural "${actual}") ${participle} '${needle}', but should have ${expected}"
  message="${message}"$'\n'"$(string_match_footer "${mode}" "${case_sensitive}" "${case_decided}")"

  format_error "${message}" | flunk
}
