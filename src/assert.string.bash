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
  if [ "${1-}" = "" ]; then
    return 0
  else
    format_error "String '${1}' is not empty" | flunk
  fi
}

##
# Asserts that a string is not empty.
#
# Arguments:
#   1. string: String to check.
##
assert_not_empty() {
  if [ "${1-}" = "" ]; then
    format_error "String '${1}' is empty, but should not be" | flunk
  else
    return 0
  fi
}

##
# Asserts that a string contains a substring.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Substring to search for.
##
assert_string_contains() {
  string_assert_match_pair "anywhere" 0 "" "$@"
}

##
# Asserts that a string does not contain a substring.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Substring to search for.
##
assert_string_not_contains() {
  string_assert_match_pair "anywhere" 1 "" "$@"
}

##
# Asserts that a string starts with a substring.
#
# The needle is matched against the start of the whole string rather than the
# start of each of its lines.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Substring to search for.
##
assert_string_starts_with() {
  string_assert_match_pair "start" 0 "" "$@"
}

##
# Asserts that a string does not start with a substring.
#
# The needle is matched against the start of the whole string rather than the
# start of each of its lines.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Substring to search for.
##
assert_string_not_starts_with() {
  string_assert_match_pair "start" 1 "" "$@"
}

##
# Asserts that a string ends with a substring.
#
# The needle is matched against the end of the whole string rather than the end
# of each of its lines.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Substring to search for.
##
assert_string_ends_with() {
  string_assert_match_pair "end" 0 "" "$@"
}

##
# Asserts that a string does not end with a substring.
#
# The needle is matched against the end of the whole string rather than the end
# of each of its lines.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Substring to search for.
##
assert_string_not_ends_with() {
  string_assert_match_pair "end" 1 "" "$@"
}

##
# Asserts that a string matches an extended regular expression.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Extended regular expression to match.
##
assert_string_matches() {
  string_assert_match_pair "anywhere" 0 "--regex" "$@"
}

##
# Asserts that a string does not match an extended regular expression.
#
# Arguments:
#   1. options: Match mode options. Optional, see 'string_assert_match'.
#   2. haystack: String to search.
#   3. needle: Extended regular expression to match.
##
assert_string_not_matches() {
  string_assert_match_pair "anywhere" 1 "--regex" "$@"
}

##
# Asserts that two strings are equal.
#
# Arguments:
#   1. expected: Expected string.
#   2. actual: Actual string.
##
assert_equal() {
  if [ "${1-}" != "${2-}" ]; then
    {
      echo "expected: ${1}"
      echo "actual:   ${2}"
    } | flunk
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
  local len="${1:-8}"
  local alphabet='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local ret=''
  local i

  if ! [[ ${len} =~ ^[0-9]+$ ]]; then
    flunk "Length must be a non-negative integer."
    return 1
  fi

  # Base 10 is explicit so that a zero-padded length is not read as octal.
  len=$((10#${len}))

  # A '/dev/urandom' pipeline is not usable here: its tools' STDERR reaches the
  # caller, where Bats' 'run' merges it into the returned value, and its reader
  # can outlive the writer and hang.
  for ((i = 0; i < len; i++)); do
    ret="${ret}${alphabet:RANDOM%${#alphabet}:1}"
  done

  echo "${ret}"
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
# Arguments:
#   1. haystack: String to search.
#   2. needle: String to search for, read according to the mode.
#   3. mode: Match mode - 'literal' or 'regex'.
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

    placeholder="${format:index + 1:1}"

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
# Asserts that a needle matches a haystack the caller has already resolved.
#
# The match mode options are read from the front of the remaining arguments:
#
#   --literal         Read the needle literally. The default.
#   --regex           Read the needle as an extended regular expression.
#   --format          Read the needle as a format string, see
#                     'string_format_to_regex'.
#   --ignore-case     Match case-insensitively. The default.
#   --case-sensitive  Match case-sensitively.
#   --                End the options, for a needle that is one of them.
#
# Only an exact match of one of those is read as an option, so a needle that
# merely starts with a dash is left alone.
#
# Arguments:
#   1. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   2. negate: '1' to assert that the needle does not match.
#   3. haystack: String to search.
#   4. options: Match mode options. Optional.
#   5. needle: String to search for. Optional, read from STDIN when omitted.
##
string_assert_match() {
  local anchor="${1}"
  local negate="${2}"
  local haystack="${3}"
  shift 3

  ##
  ## Option parsing.
  ##

  local mode=""
  local case_mode=""
  local requested

  while [ "$#" -gt 0 ]; do
    case "${1}" in
      --literal | --regex | --format)
        requested="${1#--}"

        if [ -n "${mode}" ] && [ "${mode}" != "${requested}" ]; then
          flunk "Conflicting match modes '--${mode}' and '${1}'."
          return 1
        fi

        mode="${requested}"
        shift
        ;;
      --ignore-case | --case-sensitive)
        requested="${1#--}"

        if [ -n "${case_mode}" ] && [ "${case_mode}" != "${requested}" ]; then
          flunk "Conflicting case options '--${case_mode}' and '${1}'."
          return 1
        fi

        case_mode="${requested}"
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        break
        ;;
    esac
  done

  mode="${mode:-literal}"
  case_mode="${case_mode:-ignore-case}"

  local needle
  if [ "$#" -eq 0 ]; then
    needle="$(cat -)"
  elif [ "$#" -eq 1 ]; then
    needle="${1}"
  else
    flunk "Unexpected argument '${2}'. Match mode options come before the positional arguments."
    return 1
  fi

  ##
  ## Matching.
  ##

  local pattern="${needle}"
  local pattern_mode="${mode}"

  if [ "${mode}" = "format" ]; then
    pattern="$(string_format_to_regex "${needle}")" || return 1
    pattern_mode="regex"
  fi

  local case_sensitive=0
  [ "${case_mode}" = "case-sensitive" ] && case_sensitive=1

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

  local message
  if [ "${negate}" = "1" ]; then
    message="String '${haystack}' ${verb_third_person} '${needle}', but should not"
  else
    message="String '${haystack}' does not ${verb} '${needle}'"
  fi

  local case_label="insensitive"
  [ "${case_sensitive}" = "1" ] && case_label="sensitive"

  message="${message}"$'\n'"match mode: ${mode}"
  message="${message}"$'\n'"case: ${case_label}"

  # The setting that was in force is only worth naming when the other one would
  # have decided the assertion the other way.
  local opposite_case=$((1 - case_sensitive))
  local opposite_status=0
  string_match "${haystack}" "${pattern}" "${pattern_mode}" "${opposite_case}" "${anchor}" || opposite_status=$?

  if [ "${opposite_status}" -ne "${match_status}" ]; then
    if [ "${case_sensitive}" = "1" ]; then
      message="${message}"$'\n'"note: it matches with '--ignore-case'"
    else
      message="${message}"$'\n'"note: it does not match with '--case-sensitive'"
    fi
  fi

  format_error "${message}" | flunk
}

##
# Asserts on a haystack and a needle given as the last two arguments.
#
# Arguments:
#   1. anchor: Where the needle must sit - 'anywhere', 'start' or 'end'.
#   2. negate: '1' to assert that the needle does not match.
#   3. mode: Match mode option to apply before the caller's own, or an empty
#      string.
#   4. options: Match mode options. Optional, see 'string_assert_match'.
#   5. haystack: String to search.
#   6. needle: String to search for.
##
string_assert_match_pair() {
  local anchor="${1}"
  local negate="${2}"
  local mode="${3}"
  shift 3

  local -a args=()
  [ -n "${mode}" ] && args+=("${mode}")

  while [ "$#" -gt 2 ]; do
    args+=("${1}")
    shift
  done

  if [ "$#" -ne 2 ]; then
    flunk "A haystack and a needle are required."
    return 1
  fi

  args+=("--" "${2}")

  string_assert_match "${anchor}" "${negate}" "${1}" "${args[@]}"
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
