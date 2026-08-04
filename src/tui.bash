#!/usr/bin/env bash
##
# @file
# Helpers for testing Terminal User Interface (TUI) scripts.
#

##
# Runs a TUI script, feeding it a list of answers on STDIN.
#
# Each answer is submitted followed by a newline. An empty answer submits a
# blank line, so a prompt can be left at its default.
#
# The script is given a deadline, so one that keeps asking after its answers are
# spent is terminated and reported with everything it printed, rather than
# blocking until the suite is killed.
#
# Arguments:
#   1+. answers: Answers to submit, one per argument, in the order the script
#      prompts for them. Optional.
#
# Globals:
#   SCRIPT_FILE: Path to the script to run. Relative paths resolve against the
#     current directory.
#   BATS_HELPERS_TUI_TIMEOUT: Seconds the script is given to finish. Defaults
#     to 60.
#   BATS_HELPERS_TUI_ANSWERS: Set to the number of answers submitted.
#   BATS_TEST_TMPDIR: Per-test sandbox holding the script's input and output.
#   output: Set by 'run' to what the script printed.
#   status: Set by 'run' to the exit status of the script.
##
tui_run() {
  if [ -z "${SCRIPT_FILE-}" ]; then
    flunk "SCRIPT_FILE is not set."
    return 1
  fi

  if [ ! -e "${SCRIPT_FILE}" ]; then
    flunk "Script file '${SCRIPT_FILE}' does not exist."
    return 1
  fi

  if [ ! -f "${SCRIPT_FILE}" ]; then
    flunk "Script file '${SCRIPT_FILE}' is not a regular file."
    return 1
  fi

  local timeout="${BATS_HELPERS_TUI_TIMEOUT:-60}"

  if ! [[ ${timeout} =~ ^-?[0-9]+$ ]]; then
    flunk "Timeout '${timeout}' is not a whole number of seconds."
    return 1
  fi

  if [ "${timeout}" -le 0 ]; then
    flunk "Timeout must be greater than zero."
    return 1
  fi

  local dir="${BATS_TEST_TMPDIR-}"

  if [ -z "${dir}" ]; then
    # Written directly rather than through 'flunk', whose path rewriting needs
    # the non-empty sandbox path that is missing here.
    echo "TUI sandbox cannot be resolved: 'BATS_TEST_TMPDIR' is not set." >&2
    return 1
  fi

  local answers=("$@")
  local input=""
  local answer

  for answer in "${answers[@]}"; do
    if [ "${answer}" = "nothing" ]; then
      [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: the 'nothing' answer will be removed in the next version. Use an empty string instead." >&3
      answer=""
    fi

    input="${input}${answer}"$'\n'
  done

  BATS_HELPERS_TUI_ANSWERS="${#answers[@]}"

  # A bare './' would break an absolute path, and omitting it would look up a
  # relative one on PATH.
  local script_path="${SCRIPT_FILE}"
  [ "${script_path#/}" = "${script_path}" ] && script_path="./${script_path}"

  local input_file="${dir%/}/bats-helpers-tui.in"
  local output_file="${dir%/}/bats-helpers-tui.out"
  local expiry_file="${dir%/}/bats-helpers-tui.expiry"

  # Written with '%s' rather than '%b' so that an apostrophe, a '%' directive, a
  # backslash escape or a space reaches the script literally.
  printf '%s' "${input}" >"${input_file}"
  rm -f "${expiry_file}"

  run tui_exec "${script_path}" "${input_file}" "${output_file}" "${expiry_file}" "${timeout}"

  [ -f "${expiry_file}" ] || return 0

  local elapsed
  elapsed="$(cat "${expiry_file}")"

  local message="Script '${SCRIPT_FILE}' did not finish within the ${timeout} second timeout"
  message="${message}"$'\n'"elapsed: ${elapsed} second(s)"

  format_error "${message}" | flunk
}

##
# Runs a script with its answers on STDIN, terminating it at a deadline.
#
# The script runs in the background and a watchdog terminates it once the
# deadline has passed, because 'timeout' is absent on some of the platforms the
# library supports. Both background jobs redirect their own streams and close
# file descriptor 3, so neither can hold open the capture that 'run' reads from.
#
# The watchdog records the overrun only once its signal has been delivered, so a
# script that finished in the same instant is not reported as having overrun.
#
# Arguments:
#   1. script_path: Script to run.
#   2. input_file: File holding the answers.
#   3. output_file: File the script's STDOUT and STDERR are written to.
#   4. expiry_file: File written with the elapsed seconds when the deadline
#      passes, and left absent when it does not.
#   5. timeout: Seconds the script is given to finish.
#
# Outputs:
#   STDOUT: Everything the script printed, including what it printed before it
#     was terminated.
#
# Returns:
#   The exit status of the script.
##
tui_exec() {
  local script_path="${1}"
  local input_file="${2}"
  local output_file="${3}"
  local expiry_file="${4}"
  local timeout="${5}"

  local start="${SECONDS}"

  "${script_path}" <"${input_file}" >"${output_file}" 2>&1 3>&- &
  local script_pid="$!"

  # The wait is broken into short sleeps so that killing the watchdog leaves at
  # most a fraction of a second of it behind.
  (
    while [ "$((SECONDS - start))" -lt "${timeout}" ]; do
      sleep 0.1
    done

    kill -TERM "${script_pid}" 2>/dev/null || exit 0
    printf '%s\n' "$((SECONDS - start))" >"${expiry_file}"

    # A script that traps the first signal is not given the choice twice.
    sleep 1
    kill -KILL "${script_pid}" 2>/dev/null
  ) >/dev/null 2>&1 3>&- &
  local watchdog_pid="$!"

  local status=0
  wait "${script_pid}" || status="$?"

  kill -TERM "${watchdog_pid}" 2>/dev/null || true
  wait "${watchdog_pid}" 2>/dev/null || true

  cat "${output_file}"

  return "${status}"
}

##
## Assertions.
##

##
# Asserts that the script prompted in the given order, ignoring case.
#
# Arguments:
#   1+. prompts: Expected prompts, one per argument, in the order the script
#      printed them. Optional; no arguments asserts that no answer was
#      submitted.
##
tui_assert_prompts() {
  tui_prompts_assert_match 0 "$@"
}

##
# Asserts that the script prompted in the given order, case-sensitively.
#
# Arguments:
#   1+. prompts: Expected prompts, one per argument, in the order the script
#      printed them. Optional; no arguments asserts that no answer was
#      submitted.
##
tui_assert_prompts_case() {
  tui_prompts_assert_match 1 "$@"
}

##
# Asserts that the captured output holds the prompts in order.
#
# Each prompt is searched for in what is left of the output after the prompt
# before it matched, so a sequence that appears in another order is reported
# rather than passing. The number of prompts must match the number of answers
# the last run submitted, which is what catches an answer landing against the
# wrong prompt.
#
# Arguments:
#   1. case_sensitive: '1' to match case-sensitively, '0' to ignore case.
#   2+. prompts: Expected prompts, in the order the script printed them.
#
# Globals:
#   BATS_HELPERS_TUI_ANSWERS: Number of answers the last 'tui_run' submitted.
#   output: Output captured by the last 'tui_run'.
##
tui_prompts_assert_match() {
  if [ "$#" -lt 1 ]; then
    flunk "A case sensitivity flag is required."
    return 1
  fi

  local case_sensitive="${1}"
  shift

  if [ -z "${BATS_HELPERS_TUI_ANSWERS-}" ]; then
    flunk "No script has been run. Run 'tui_run' first."
    return 1
  fi

  local count="$#"

  if [ "${count}" -ne "${BATS_HELPERS_TUI_ANSWERS}" ]; then
    format_error "Script was answered ${BATS_HELPERS_TUI_ANSWERS} time(s), but ${count} prompt(s) are expected" | flunk
    return 1
  fi

  local remaining="${output-}"
  local matched=0
  local prompt
  local haystack
  local needle
  local prefix

  for prompt in "$@"; do
    if [ -z "${prompt}" ]; then
      flunk "Prompt must not be empty."
      return 1
    fi

    haystack="${remaining}"
    needle="${prompt}"

    # Folding both sides is what makes the position of the match, rather than
    # only its presence, available for an insensitive comparison: prefix removal
    # does not honour 'nocasematch'.
    if [ "${case_sensitive}" != "1" ]; then
      haystack="${haystack,,}"
      needle="${needle,,}"
    fi

    # '%%' strips the longest matching suffix, leaving the text before the first
    # occurrence. The needle is quoted so that it is read literally.
    prefix="${haystack%%"${needle}"*}"

    if [ "${#prefix}" -eq "${#haystack}" ]; then
      format_error "Prompt '${prompt}' does not appear in the remaining output"$'\n'"matched: ${matched} of ${count}" | flunk
      return 1
    fi

    remaining="${remaining:$((${#prefix} + ${#needle}))}"
    matched=$((matched + 1))
  done
}
