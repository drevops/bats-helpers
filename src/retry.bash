#!/usr/bin/env bash
##
# @file
# Retry for conditions that become true shortly.
#

##
# Runs a command until it succeeds.
#
# The command is re-run until it exits zero, until the attempt count is spent or
# until the deadline is reached, whichever comes first. Nothing is waited for
# before the first attempt or after the last one, so a condition that is already
# true costs no delay at all.
#
# Each attempt runs in a subshell with its output captured, the way 'run' does,
# so 'set -e' does not apply inside it and a variable an attempt sets does not
# reach the test. An attempt that has to publish a value writes a file.
#
# Arguments:
#   1. attempts: Number of attempts to make. Greater than zero.
#   2. delay: Seconds to wait between attempts. Decimals are allowed.
#   3. command: Command or assertion to run.
#   4+. args: Arguments to pass to the command. Optional.
#
# Globals:
#   BATS_HELPERS_RETRY_TIMEOUT: Overall deadline, in whole seconds. Optional.
#     The retry stops once a failed attempt finds the deadline reached, rather
#     than waiting again; an attempt already running is not interrupted.
#   BATS_HELPERS_RETRY_ATTEMPTS: Set to the number of attempts made, which on
#     success is the attempt that succeeded.
#   BATS_HELPERS_RETRY_OUTPUT: Set to the STDOUT and STDERR of the last attempt.
#   BATS_HELPERS_RETRY_ELAPSED: Set to the whole seconds spent.
#
# Outputs:
#   File descriptor 3: A notice naming the attempt the command succeeded on.
#     Nothing when it succeeded on the first one.
##
retry_run() {
  if [ "$#" -lt 3 ]; then
    flunk "An attempt count, a delay and a command are required."
    return 1
  fi

  local attempts="${1}"
  local delay="${2}"
  shift 2

  local -a command_line=("$@")
  local command_name="${1}"

  ##
  ## Input validation.
  ##

  if ! [[ ${attempts} =~ ^-?[0-9]+$ ]]; then
    flunk "Attempt count '${attempts}' is not an integer."
    return 1
  fi

  if [ "${attempts}" -le 0 ]; then
    flunk "Attempt count must be greater than zero."
    return 1
  fi

  if ! [[ ${delay} =~ ^[0-9]*\.?[0-9]+$ ]]; then
    flunk "Delay '${delay}' is not a non-negative number."
    return 1
  fi

  if [ -z "${command_name}" ]; then
    flunk "Command name must not be empty."
    return 1
  fi

  # A name that does not resolve fails every attempt with the same status, so
  # retrying it only delays the report of something that was wrong from the
  # start. A command that is expected to appear is probed for by a function.
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    flunk "Command '${command_name}' is not a valid command."
    return 1
  fi

  local timeout="${BATS_HELPERS_RETRY_TIMEOUT-}"

  if [ -n "${timeout}" ] && ! [[ ${timeout} =~ ^[0-9]+$ ]]; then
    flunk "Deadline '${timeout}' is not a whole number of seconds."
    return 1
  fi

  ##
  ## Runner.
  ##

  BATS_HELPERS_RETRY_ATTEMPTS=0
  BATS_HELPERS_RETRY_OUTPUT=""
  BATS_HELPERS_RETRY_ELAPSED=0

  # 'SECONDS' is the only clock available across the Bash versions the library
  # supports, which is why the deadline is counted in whole seconds.
  local start="${SECONDS}"
  local last_status
  local deadline_reached=0

  while true; do
    BATS_HELPERS_RETRY_ATTEMPTS=$((BATS_HELPERS_RETRY_ATTEMPTS + 1))

    last_status=0
    BATS_HELPERS_RETRY_OUTPUT="$("${command_line[@]}" 2>&1)" || last_status="$?"

    BATS_HELPERS_RETRY_ELAPSED=$((SECONDS - start))

    if [ "${last_status}" -eq 0 ]; then
      # A test that quietly degrades to a fourth attempt reads as a healthy one
      # unless the run says otherwise.
      [ "${BATS_HELPERS_RETRY_ATTEMPTS}" -eq 1 ] || echo "Retried: '${command_name}' succeeded on attempt ${BATS_HELPERS_RETRY_ATTEMPTS} of ${attempts} after ${BATS_HELPERS_RETRY_ELAPSED} seconds." >&3

      return 0
    fi

    if [ "${BATS_HELPERS_RETRY_ATTEMPTS}" -ge "${attempts}" ]; then
      break
    fi

    if [ -n "${timeout}" ] && [ "${BATS_HELPERS_RETRY_ELAPSED}" -ge "${timeout}" ]; then
      deadline_reached=1
      break
    fi

    sleep "${delay}"
  done

  ##
  ## Failure report.
  ##

  local bound="${attempts} attempt(s)"

  if [ "${deadline_reached}" = "1" ]; then
    bound="the ${timeout} second deadline"
  fi

  format_error "Command did not succeed within the retry limit" \
    "command" "${command_name}" \
    "limit" "${bound}" \
    "attempts" "${BATS_HELPERS_RETRY_ATTEMPTS}" \
    "elapsed" "${BATS_HELPERS_RETRY_ELAPSED} second(s)" \
    "last status" "${last_status}" \
    "last output" "${BATS_HELPERS_RETRY_OUTPUT}" | flunk
}
