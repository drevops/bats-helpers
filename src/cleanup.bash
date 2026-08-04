#!/usr/bin/env bash
##
# @file
# Deferred cleanup for the current test.
#

##
# Resolves the file that the current test's cleanup registry is stored in.
#
# Globals:
#   BATS_HELPERS_CLEANUP_DIR: Directory holding the registry. Defaults to the
#     per-test temporary directory, so that BATS removes the registry with the
#     rest of the test sandbox.
#
# Outputs:
#   STDOUT: The registry path.
#   STDERR: The error message when the directory cannot be resolved.
#
# Returns:
#   1 when neither of the globals is set.
##
cleanup_registry_path() {
  local dir="${BATS_HELPERS_CLEANUP_DIR:-${BATS_TEST_TMPDIR-}}"

  if [ -z "${dir}" ]; then
    # Written directly rather than through 'flunk', whose path rewriting needs
    # the non-empty BATS_TEST_TMPDIR that is missing here.
    echo "Cleanup registry cannot be resolved: 'BATS_TEST_TMPDIR' is not set. Set BATS_HELPERS_CLEANUP_DIR to a writable directory." >&2
    return 1
  fi

  echo "${dir%/}/bats-helpers-cleanup"
}

##
# Registers a command to run once the current test has finished.
#
# The registry lives in a file rather than in a variable, so a registration
# made inside a subshell - under 'run', a command substitution or a pipeline -
# still reaches the runner.
#
# Arguments:
#   1. command: Command to run.
#   2+. args: Arguments to pass to the command. Optional.
##
cleanup_register() {
  if [ "$#" -eq 0 ] || [ -z "${1}" ]; then
    flunk "Cleanup command is required."
    return 1
  fi

  local registry
  registry="$(cleanup_registry_path)" || return 1

  local dir
  dir="$(dirname "${registry}")"

  if ! mkdir -p "${dir}"; then
    flunk "Cleanup registry directory '${dir}' cannot be created."
    return 1
  fi

  # Quoting the arguments here snapshots them, so reassigning a variable after
  # the call cannot redirect the command that was registered. '%q' escapes a
  # newline as well, keeping one registration on one line.
  local line
  line="$(printf '%q ' "$@")"

  printf '%s\n' "${line% }" >>"${registry}"
}

##
# Runs the commands registered for the current test, in reverse order.
#
# Call this function from your test's teardown() method.
#
# The registry is drained before the commands run, so a second call runs
# nothing and a command that registers another one does not re-enter this
# function.
##
cleanup_run() {
  local registry
  registry="$(cleanup_registry_path)" || return 1

  if [ ! -f "${registry}" ]; then
    return 0
  fi

  local commands=()
  local line
  while IFS= read -r line; do
    commands+=("${line}")
  done <"${registry}"

  if ! rm -f "${registry}"; then
    flunk "Cleanup registry '${registry}' cannot be removed."
    return 1
  fi

  local run_status=0
  local command_status
  local i
  for ((i = ${#commands[@]} - 1; i >= 0; i--)); do
    command_status=0
    # 'eval' undoes the quoting 'cleanup_register' applied, turning the line
    # back into the argument vector it was registered with. Running the line
    # unevaluated would look for one command named after the whole of it.
    eval "${commands[${i}]}" || command_status="$?"

    if [ "${command_status}" -ne 0 ]; then
      # 'flunk' returns non-zero, so the assignment both records the failure and
      # keeps the remaining commands running under errexit.
      flunk "Cleanup command '${commands[${i}]}' failed with exit status ${command_status}." || run_status=1
    fi
  done

  return "${run_status}"
}
