#!/usr/bin/env bash
##
# @file
# Assertions for strings.
#

##
# Asserts that a string is empty.
#
# Arguments:
#   1. string: String to check.
##
assert_empty() {
  if [ -z "${1-}" ]; then
    return 0
  else
    format_error "String is not empty" "string" "${1}" | flunk
  fi
}

##
# Asserts that a string is not empty.
#
# Arguments:
#   1. string: String to check.
##
assert_not_empty() {
  if [ -n "${1-}" ]; then
    return 0
  else
    format_error "String is empty, but should not be" | flunk
  fi
}

##
# Asserts that two strings are equal.
#
# Arguments:
#   1. expected: Expected string.
#   2. actual: Actual string.
##
assert_equal() {
  if [ "${1-}" = "${2-}" ]; then
    return 0
  else
    format_error "Strings are not equal" "expected" "${1-}" "actual" "${2-}" | flunk
  fi
}

##
## Containment assertions.
##

##
# Asserts that a string contains a substring, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_contains() {
  _string_assert_match "string" "anywhere" 0 "literal" 0 "$@"
}

##
# Asserts that a string contains a substring, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_contains_case() {
  _string_assert_match "string" "anywhere" 0 "literal" 1 "$@"
}

##
# Asserts that a string does not contain a substring, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_contains() {
  _string_assert_match "string" "anywhere" 1 "literal" 0 "$@"
}

##
# Asserts that a string does not contain a substring, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_contains_case() {
  _string_assert_match "string" "anywhere" 1 "literal" 1 "$@"
}

##
## Regular expression assertions.
##

##
# Asserts that a string matches a regular expression, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Extended regular expression to match.
##
assert_string_matches() {
  _string_assert_match "string" "anywhere" 0 "regex" 0 "$@"
}

##
# Asserts that a string matches a regular expression, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Extended regular expression to match.
##
assert_string_matches_case() {
  _string_assert_match "string" "anywhere" 0 "regex" 1 "$@"
}

##
# Asserts that a string does not match a regular expression, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Extended regular expression to match.
##
assert_string_not_matches() {
  _string_assert_match "string" "anywhere" 1 "regex" 0 "$@"
}

##
# Asserts that a string does not match a regular expression, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Extended regular expression to match.
##
assert_string_not_matches_case() {
  _string_assert_match "string" "anywhere" 1 "regex" 1 "$@"
}

##
## Format assertions.
##

##
# Asserts that a string matches a format string, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Format string, see 'string_format_to_regex'.
##
assert_string_matches_format() {
  _string_assert_match "string" "anywhere" 0 "format" 0 "$@"
}

##
# Asserts that a string matches a format string, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Format string, see 'string_format_to_regex'.
##
assert_string_matches_format_case() {
  _string_assert_match "string" "anywhere" 0 "format" 1 "$@"
}

##
# Asserts that a string does not match a format string, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Format string, see 'string_format_to_regex'.
##
assert_string_not_matches_format() {
  _string_assert_match "string" "anywhere" 1 "format" 0 "$@"
}

##
# Asserts that a string does not match a format string, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Format string, see 'string_format_to_regex'.
##
assert_string_not_matches_format_case() {
  _string_assert_match "string" "anywhere" 1 "format" 1 "$@"
}

##
## Prefix and suffix assertions.
##

# The needle is matched against the start or the end of the whole string rather
# than of each of its lines.

##
# Asserts that a string starts with a substring, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_starts_with() {
  _string_assert_match "string" "start" 0 "literal" 0 "$@"
}

##
# Asserts that a string starts with a substring, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_starts_with_case() {
  _string_assert_match "string" "start" 0 "literal" 1 "$@"
}

##
# Asserts that a string does not start with a substring, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_starts_with() {
  _string_assert_match "string" "start" 1 "literal" 0 "$@"
}

##
# Asserts that a string does not start with a substring, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_starts_with_case() {
  _string_assert_match "string" "start" 1 "literal" 1 "$@"
}

##
# Asserts that a string ends with a substring, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_ends_with() {
  _string_assert_match "string" "end" 0 "literal" 0 "$@"
}

##
# Asserts that a string ends with a substring, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_ends_with_case() {
  _string_assert_match "string" "end" 0 "literal" 1 "$@"
}

##
# Asserts that a string does not end with a substring, ignoring case.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_ends_with() {
  _string_assert_match "string" "end" 1 "literal" 0 "$@"
}

##
# Asserts that a string does not end with a substring, case-sensitively.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: Substring to search for.
##
assert_string_not_ends_with_case() {
  _string_assert_match "string" "end" 1 "literal" 1 "$@"
}

##
## Matching.
##

##
# Reports whether a needle matches a haystack.
#
# Both anchors apply to the whole haystack rather than to each of its lines, so
# a regular expression anchored with '^' or '$' behaves the same way.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. haystack: String to search.
#   2. needle: String to search for, read according to the mode.
#   3. mode: How the needle is read - 'literal' or 'regex'.
#   4. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   5. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#
# Returns:
#   0 when the needle matches, 1 when it does not, and 2 when the needle is not
#   a usable extended regular expression.
##
string_match() {
  local haystack="${1}"
  local needle="${2}"
  local mode="${3}"
  local case_sensitive="${4}"
  local anchor="${5}"

  local nocasematch_was_set=0
  if shopt -q nocasematch; then
    nocasematch_was_set=1
  fi

  if [ "${case_sensitive}" = "1" ]; then
    shopt -u nocasematch
  else
    shopt -s nocasematch
  fi

  local result=1

  if [ "${mode}" = "literal" ]; then
    case "${anchor}" in
      start)
        [[ ${haystack} == "${needle}"* ]] && result=0
        ;;
      end)
        [[ ${haystack} == *"${needle}" ]] && result=0
        ;;
      *)
        [[ ${haystack} == *"${needle}"* ]] && result=0
        ;;
    esac
  else
    local pattern="${needle}"

    case "${anchor}" in
      start)
        pattern="^(${needle})"
        ;;
      end)
        pattern="(${needle})$"
        ;;
    esac

    # A needle Bash cannot compile makes '[[ =~ ]]' write its own diagnostic,
    # which would reach the test output ahead of the library's own message.
    { [[ ${haystack} =~ ${pattern} ]] && result=0; } 2>/dev/null || result=$?
  fi

  if [ "${nocasematch_was_set}" = "1" ]; then
    shopt -s nocasematch
  else
    shopt -u nocasematch
  fi

  return "${result}"
}

##
# Translates a format string into an extended regular expression.
#
# Everything outside a placeholder is escaped, so the expression matches the
# format string literally apart from the runs the placeholders stand for.
#
# Arguments:
#   1. format: Format string. '%d' stands for a run of digits, '%f' for a number
#      with an optional fractional part, '%s' for a run of non-whitespace
#      characters, and '%%' for a literal '%'.
#
# Outputs:
#   STDOUT: The extended regular expression.
##
string_format_to_regex() {
  local format="${1}"
  local regex=""
  local index=0
  local char
  local placeholder

  while [ "${index}" -lt "${#format}" ]; do
    char="${format:index:1}"

    if [ "${char}" != "%" ]; then
      # shellcheck disable=SC1003
      case "${char}" in
        '\' | '.' | '|' | '$' | '(' | ')' | '[' | ']' | '{' | '}' | '?' | '+' | '*' | '^')
          regex="${regex}\\${char}"
          ;;
        *)
          regex="${regex}${char}"
          ;;
      esac

      index=$((index + 1))
      continue
    fi

    placeholder="${format:index+1:1}"

    case "${placeholder}" in
      d)
        regex="${regex}[0-9]+"
        ;;
      f)
        regex="${regex}[0-9]+(\\.[0-9]+)?"
        ;;
      s)
        regex="${regex}[^[:space:]]+"
        ;;
      %)
        regex="${regex}%"
        ;;
      *)
        flunk "Unknown format placeholder '%${placeholder}'. Use '%d', '%f', '%s' or '%%'."
        return 1
        ;;
    esac

    index=$((index + 2))
  done

  printf '%s\n' "${regex}"
}

##
# Asserts that a needle matches a haystack, reporting how on failure.
#
# Arguments:
#   1. subject: What the haystack is - 'string', 'output', 'stderr' or 'file'.
#      Opens the title with the matching noun and keys the haystack row.
#   2. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   3. negate: '1' to assert that the needle does not match.
#   4. mode: How the needle is read - 'literal', 'regex' or 'format'.
#   5. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   6. haystack: String to search.
#   7. needle: String to search for.
#   8. file: Path the haystack was read from, reported as the 'file' row while
#      the haystack reports under 'contents'. Required with subject 'file',
#      absent otherwise.
##
_string_assert_match() {
  local expected_count=7
  [ "${1-}" = "file" ] && expected_count=8

  if [ "$#" -ne "${expected_count}" ]; then
    flunk "A haystack and a needle are required."
    return 1
  fi

  local subject="${1}"
  local anchor="${2}"
  local negate="${3}"
  local mode="${4}"
  local case_sensitive="${5}"
  local haystack="${6}"
  local needle="${7}"

  ##
  ## Matching.
  ##

  local pattern="${needle}"
  local pattern_mode="${mode}"

  if [ "${mode}" = "format" ]; then
    pattern="$(string_format_to_regex "${needle}")" || return 1
    pattern_mode="regex"
  fi

  local match_status=0
  string_match "${haystack}" "${pattern}" "${pattern_mode}" "${case_sensitive}" "${anchor}" || match_status=$?

  if [ "${match_status}" -eq 2 ]; then
    flunk "Invalid regular expression '${needle}'."
    return 1
  fi

  if [ "${negate}" = "1" ]; then
    [ "${match_status}" -ne 0 ] && return 0
  else
    [ "${match_status}" -eq 0 ] && return 0
  fi

  ##
  ## Failure report.
  ##

  local noun
  noun="$(_string_needle_noun "${mode}")"

  local verb
  local verb_third_person

  case "${anchor}" in
    start)
      verb="start with"
      verb_third_person="starts with"
      ;;
    end)
      verb="end with"
      verb_third_person="ends with"
      ;;
    *)
      if [ "${mode}" = "literal" ]; then
        verb="contain"
        verb_third_person="contains"
      else
        verb="match"
        verb_third_person="matches"
      fi
      ;;
  esac

  local subject_noun
  subject_noun="$(_string_subject_noun "${subject}")"

  local title
  if [ "${negate}" = "1" ]; then
    title="${subject_noun} ${verb_third_person} ${noun}, but should not"
  else
    title="${subject_noun} does not ${verb} ${noun}"
  fi

  # The setting that was in force is only worth naming when the other one would
  # have decided the assertion the other way.
  local opposite_case=$((1 - case_sensitive))
  local opposite_status=0
  string_match "${haystack}" "${pattern}" "${pattern_mode}" "${opposite_case}" "${anchor}" || opposite_status=$?

  local case_decided=0
  [ "${opposite_status}" -ne "${match_status}" ] && case_decided=1

  local -a subject_rows=("${subject}" "${haystack}")

  if [ "${subject}" = "file" ]; then
    subject_rows=("file" "${8}" "contents" "${haystack}")
  fi

  local -a footer=()
  mapfile -t footer < <(_string_match_rows "${mode}" "${case_sensitive}" "${case_decided}")

  format_error "${title}" "${subject_rows[@]}" "${noun}" "${needle}" "${footer[@]}" | flunk
}

##
# Names the kind of needle a match mode reads.
#
# Arguments:
#   1. mode: How the needle is read - 'literal', 'regex' or 'format'.
#
# Outputs:
#   STDOUT: The noun.
##
_string_needle_noun() {
  case "${1}" in
    regex)
      printf 'regular expression\n'
      ;;
    format)
      printf 'format\n'
      ;;
    *)
      printf 'substring\n'
      ;;
  esac
}

##
# Names the subject a match assertion reports under.
#
# Arguments:
#   1. subject: What was searched - 'string', 'output', 'stderr' or 'file'.
#
# Outputs:
#   STDOUT: The capitalised noun the title opens with.
##
_string_subject_noun() {
  case "${1}" in
    output)
      printf 'Output\n'
      ;;
    stderr)
      printf 'Stderr\n'
      ;;
    file)
      printf 'File\n'
      ;;
    *)
      printf 'String\n'
      ;;
  esac
}

##
# Describes how a failed match was performed, as rows for a failure report.
#
# Arguments:
#   1. mode: How the needle was read - 'literal', 'regex' or 'format'.
#   2. case_sensitive: '1' when the match was case-sensitive, '0' when not.
#   3. case_decided: '1' when the opposite case setting would have decided the
#      assertion the other way.
#
# Outputs:
#   STDOUT: Alternating keys and values, one per line, ending with a note naming
#           the case setting when it is what decided the outcome.
##
_string_match_rows() {
  local mode="${1}"
  local case_sensitive="${2}"
  local case_decided="${3}"

  local case_label="insensitive"
  [ "${case_sensitive}" = "1" ] && case_label="sensitive"

  printf '%s\n' "match mode" "${mode}" "case" "${case_label}"

  [ "${case_decided}" = "1" ] || return 0

  if [ "${case_sensitive}" = "1" ]; then
    printf '%s\n' "note" "it matches without the '_case' suffix"
  else
    printf '%s\n' "note" "it does not match with the '_case' suffix"
  fi
}

##
# Generates a random alphanumeric string.
#
# Arguments:
#   1. length: Number of characters to generate. Optional, defaults to 8.
#
# Outputs:
#   STDOUT: The generated string.
##
string_random() {
  local length="${1:-8}"
  local alphabet='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local ret=''
  local i

  if ! [[ ${length} =~ ^[0-9]+$ ]]; then
    flunk "Length must be a non-negative integer."
    return 1
  fi

  # Base 10 is explicit so that a zero-padded length is not read as octal.
  length=$((10#${length}))

  # A '/dev/urandom' pipeline is not usable here: its tools' STDERR reaches the
  # caller, where Bats' 'run' merges it into the returned value, and its reader
  # can outlive the writer and hang.
  for ((i = 0; i < length; i++)); do
    ret="${ret}${alphabet:RANDOM%${#alphabet}:1}"
  done

  printf '%s\n' "${ret}"
}

##
## Deprecated aliases, removed in the next version.
##

assert_contains() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_contains' will be removed in the next version. Use 'assert_string_contains' instead." >&3
  assert_string_contains "${2-}" "${1-}"
}

assert_not_contains() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'assert_not_contains' will be removed in the next version. Use 'assert_string_not_contains' instead." >&3
  assert_string_not_contains "${2-}" "${1-}"
}

random_string() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'random_string' will be removed in the next version. Use 'string_random' instead." >&3
  string_random "$@"
}
