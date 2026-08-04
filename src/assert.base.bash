#!/usr/bin/env bash
##
# @file
# Failure reporting and error message formatting.
#

##
# Fails the test with a message.
#
# Arguments:
#   1. message: Message to print. Optional, read from STDIN when omitted.
#
# Globals:
#   BATS_TEST_SOURCE, BATS_TEST_FILENAME, BATS_ROOT: Read to resolve the frames
#     of the stack trace back to the files the consumer wrote.
#
# Outputs:
#   STDERR: The message, followed by the stack trace of the caller, with the
#           volatile paths rewritten to the names of the variables holding them.
#
# Returns:
#   1 always.
##
flunk() {
  local message

  if [ "$#" -eq 0 ]; then
    message="$(cat -)"
  else
    message="$*"
  fi

  local trace
  trace="$(report_stack_trace)"

  if [ "${trace}" != "" ]; then
    message="${message}"$'\n\n'"$(report_decorate "stack trace" "${trace}")"
  fi

  report_normalise_paths "${message}" >&2

  return 1
}

##
# Formats a failure report as a decorated block of aligned rows.
#
# A row whose value spans lines switches every row to a labelled form carrying
# its line count, so that two values stay comparable rather than one of them
# collapsing onto a single line and the other not. Rows keyed 'expected' and
# 'actual' are then replaced by a unified diff of the two.
#
# Arguments:
#   1. title: Short summary naming what went wrong.
#   2+. key value: Rows, given as a key and a value each. Optional.
#
# Outputs:
#   STDOUT: The formatted report.
##
format_error() {
  if [ "$#" -eq 0 ]; then
    flunk "A failure report requires a title."
    return 1
  fi

  local title="${1}"
  shift

  if [ $(($# % 2)) -ne 0 ]; then
    flunk "Failure report rows require a key and a value each."
    return 1
  fi

  ##
  ## Row collection.
  ##

  local -a keys=()
  local -a values=()
  local width=0
  local multiline=0
  local expected_index=-1
  local actual_index=-1

  while [ "$#" -gt 0 ]; do
    case "${1}" in
      expected) expected_index="${#keys[@]}" ;;
      actual) actual_index="${#keys[@]}" ;;
    esac

    [ "${#1}" -gt "${width}" ] && width="${#1}"
    [[ ${2} == *$'\n'* ]] && multiline=1

    keys+=("${1}")
    values+=("${2}")

    shift 2
  done

  local diffable=0
  if [ "${multiline}" = "1" ] && [ "${expected_index}" -ge 0 ] && [ "${actual_index}" -ge 0 ]; then
    diffable=1
  fi

  ##
  ## Rendering.
  ##

  local body=""
  local count
  local i

  for ((i = 0; i < ${#keys[@]}; i++)); do
    if [ "${diffable}" = "1" ] && [ "${i}" -eq "${actual_index}" ]; then
      continue
    fi

    if [ "${diffable}" = "1" ] && [ "${i}" -eq "${expected_index}" ]; then
      body="${body}$(report_diff "${values[expected_index]}" "${values[actual_index]}")"$'\n'
      continue
    fi

    if [ "${multiline}" = "1" ]; then
      count="$(report_count_lines "${values[i]}")"
      body="${body}${keys[i]} ($(report_plural_lines "${count}")):"$'\n'"${values[i]}"$'\n'
      continue
    fi

    body="${body}$(printf '%-*s : %s' "${width}" "${keys[i]}" "${values[i]}")"$'\n'
  done

  report_normalise_paths "$(report_decorate "${title}" "${body%$'\n'}")"
}

##
## Rendering.
##

##
# Wraps a block of text in a titled border.
#
# Arguments:
#   1. title: Title to name the block with.
#   2. body: Text to wrap. Optional, an empty body prints no line of its own.
#
# Outputs:
#   STDOUT: The decorated block.
##
report_decorate() {
  printf -- '-- %s --\n' "${1}"

  if [ "${2-}" != "" ]; then
    printf '%s\n' "${2}"
  fi

  printf -- '--\n'
}

##
# Renders a unified diff of two values.
#
# Arguments:
#   1. expected: Expected value.
#   2. actual: Actual value.
#
# Outputs:
#   STDOUT: The diff, labelled with the name of each side.
##
report_diff() {
  local -a options=(-u -L expected -L actual)

  if report_color_enabled; then
    options+=(--color=always)
  fi

  # A difference is what this function is called to render, and 'diff' reports
  # one with a non-zero status.
  diff "${options[@]}" <(printf '%s\n' "${1}") <(printf '%s\n' "${2}") || true
}

##
# Counts the lines a value spans.
#
# Arguments:
#   1. value: Value to measure.
#
# Outputs:
#   STDOUT: The number of lines, at least one.
##
report_count_lines() {
  local stripped="${1//$'\n'/}"

  printf '%s\n' "$((${#1} - ${#stripped} + 1))"
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
report_plural_lines() {
  if [ "${1}" -eq 1 ]; then
    printf '1 line\n'
    return 0
  fi

  printf '%s lines\n' "${1}"
}

##
## Colour.
##

##
# Reports whether a diff should be coloured.
#
# Globals:
#   BATS_HELPERS_REPORT_COLOR: '0' to never colour, '1' to colour whenever the
#     platform supports it. Unset or empty defers to 'NO_COLOR'.
#   NO_COLOR: Any non-empty value suppresses colour.
#
# Returns:
#   0 when the diff should be coloured, 1 when it should not.
##
report_color_enabled() {
  local override="${BATS_HELPERS_REPORT_COLOR-}"

  [ "${override}" = "0" ] && return 1

  if [ "${override}" != "1" ] && [ "${NO_COLOR-}" != "" ]; then
    return 1
  fi

  report_diff_color_supported
}

##
# Reports whether the platform's 'diff' understands the colour flag.
#
# The flag is absent from busybox diff and from GNU diffutils before 3.4, where
# passing it unconditionally would replace the report with a usage error.
#
# Returns:
#   0 when the flag is understood, 1 when it is not.
##
report_diff_color_supported() {
  diff --color=always /dev/null /dev/null >/dev/null 2>&1
}

##
## Context.
##

##
# Prints where the failing assertion was called from.
#
# The frames of the library itself and of bats-core are left out, so that a
# failure raised several calls deep inside a helper still names the line of the
# consumer's own code that reached it.
#
# Globals:
#   BATS_ROOT: Installation directory of bats-core, whose frames are skipped.
#
# Outputs:
#   STDOUT: One 'file:line: function' entry per frame, outermost last. Nothing
#           when every frame belongs to the library or to bats-core.
##
report_stack_trace() {
  local root="${BASH_SOURCE[0]%/*}"
  local bats_root="${BATS_ROOT-}"
  local source
  local i

  for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
    source="${BASH_SOURCE[i + 1]-}"

    # The outermost frame is entered from the command line rather than from a
    # file, and there is nothing above it to walk to.
    [ "${source}" = "" ] && break

    if [[ ${source} == "${root}"/* ]]; then
      continue
    fi

    if [ "${bats_root}" != "" ] && [[ ${source} == "${bats_root}"/* ]]; then
      continue
    fi

    printf '%s:%s: %s\n' "${source}" "${BASH_LINENO[i]}" "${FUNCNAME[i]}"
  done
}

##
# Rewrites the paths that change between runs to the names holding them.
#
# The bats-core temporary directories nest, so they are rewritten from the most
# specific to the least, and the working directory and the home directory are
# rewritten last for the same reason.
#
# Arguments:
#   1. text: Text to rewrite.
#
# Globals:
#   BATS_TEST_SOURCE, BATS_TEST_FILENAME: Resolve the preprocessed copy of the
#     test file back to the file the consumer wrote.
#   BATS_TEST_TMPDIR, BATS_FILE_TMPDIR, BATS_SUITE_TMPDIR, BATS_RUN_TMPDIR, PWD,
#     HOME: Rewritten to their own names.
#
# Outputs:
#   STDOUT: The rewritten text.
##
report_normalise_paths() {
  local text="${1}"

  if [ "${BATS_TEST_SOURCE-}" != "" ] && [ "${BATS_TEST_FILENAME-}" != "" ]; then
    text="${text//"${BATS_TEST_SOURCE}"/${BATS_TEST_FILENAME}}"
  fi

  local name
  local value
  local token

  for name in BATS_TEST_TMPDIR BATS_FILE_TMPDIR BATS_SUITE_TMPDIR BATS_RUN_TMPDIR PWD HOME; do
    value="${!name-}"

    # The root directory is a prefix of every path, so rewriting it would leave
    # nothing readable behind.
    if [ "${value}" = "" ] || [ "${value}" = "/" ]; then
      continue
    fi

    token="\${${name}}"
    text="${text//"${value}"/${token}}"
  done

  printf '%s\n' "${text}"
}
