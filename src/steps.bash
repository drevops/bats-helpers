#!/usr/bin/env bash
##
# @file
# Step runner for sequences of mocked command and output assertions.
#

##
# Sets up and processes a sequence of string and mocked command assertions.
#
# Steps that mock commands need two calls: the 'setup' phase creates the mocks,
# and the 'assert' phase checks how they were called. Steps that only assert on
# output need the 'assert' phase alone.
#
#   declare -a STEPS=( ... )
#   mocks="$(steps_run "setup")"
#   # ... code to be tested ...
#   steps_run "assert" "${mocks}"
#
# Each step takes one of three forms:
#
#   @<command> [<args>] # <status> [ # <output> [ # <side_effect> ]]
#     Mocks <command>. The status may be omitted and the output given in its
#     place, unless that output is all digits, which parses as a status. The
#     side effect is Bash code run when the mock is called. A command may be
#     mocked by several steps; every call goes through the same mock. Literal
#     '#' characters in <args> are escaped as '\#'.
#
#   <substring>
#     Asserts that the output contains <substring>.
#
#   - <substring>
#     Asserts that the output does not contain <substring>.
#
# See README.md for worked examples.
#
# Arguments:
#   1. phase: Either 'setup' or 'assert'. Optional, defaults to 'assert'.
#   2. mocked_commands: Mocks returned by the 'setup' phase. Required for the
#      'assert' phase.
#
# Globals:
#   STEPS: Array of steps to process.
#   RUN_STEPS_DEBUG: Set to '1' to enable debug output.
#
# Outputs:
#   STDOUT: The created mocks, in the 'setup' phase only.
##
steps_run() {
  local PHASE_SETUP="setup"
  local PHASE_ASSERT="assert"

  local phase="${1:-${PHASE_ASSERT}}"
  local mocked_commands_var="${2-}"

  if [ -z "${STEPS+x}" ]; then
    flunk "STEPS array is empty."
    return 1
  fi

  declare -A command_indexes
  declare -A mocked_commands

  steps_debug "Phase       : ${phase}"
  steps_debug "Total steps : ${#STEPS[@]}"
  steps_debug

  # Create associative array for mocked commands.
  if [[ -n ${mocked_commands_var} ]]; then
    local line
    while IFS= read -r line; do
      local key="${line%%=*}"
      local value="${line#*=}"
      mocked_commands["${key}"]="${value}"
    done <<<"${mocked_commands_var}"
  fi

  local mock
  local command_index
  local i
  for ((i = 0; i < ${#STEPS[@]}; i++)); do
    local item="${STEPS[${i}]}"

    steps_debug "STEP START: '${item}'"

    ##
    ## Command.
    ##
    if [[ ${item} == "@"* ]]; then
      steps_debug "Type: command"
      steps_debug

      ##
      ## Parsing the command, status, and optional output.
      ##

      steps_debug_sub "PARSE: STARTED"

      # Replace escaped hashes with a placeholder before parsing.
      local ESCAPED_HASH_PLACEHOLDER="__ESCAPED_HASH__"
      local item_with_placeholders="${item//\\#/${ESCAPED_HASH_PLACEHOLDER}}"

      if [[ ${item_with_placeholders} =~ (##) || $(echo "${item_with_placeholders}" | grep -o "#" | wc -l) -gt 3 ]]; then
        flunk "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
        return 1
      fi

      # Split command, status, and optional output.
      local command_parts
      IFS='#' read -ra command_parts <<<"${item_with_placeholders}"
      command_parts=("${command_parts[@]/# /}") # Remove leading spaces.
      command_parts=("${command_parts[@]/% /}") # Remove trailing spaces.

      # Extract the command binary and its arguments from the first command part.
      local full_command
      IFS=' ' read -ra full_command <<<"${command_parts[0]:1}" # Removing '@'.
      local command_binary="${full_command[0]}"
      local command_args="${full_command[*]:1}" # Extract all elements except the first one.

      local mock_status="${command_parts[1]-}"
      local mock_output="${command_parts[2]-}"
      local mock_side_effect="${command_parts[3]-}"

      # Restore escaped hashes in all parsed components.
      command_args="${command_args//${ESCAPED_HASH_PLACEHOLDER}/#}"
      mock_status="${mock_status//${ESCAPED_HASH_PLACEHOLDER}/#}"
      mock_output="${mock_output//${ESCAPED_HASH_PLACEHOLDER}/#}"
      mock_side_effect="${mock_side_effect//${ESCAPED_HASH_PLACEHOLDER}/#}"

      if ! [[ ${mock_status} =~ ^[0-9]+$ ]]; then
        steps_debug_sub "PARSE: Converting output to '${mock_status}' output."
        steps_debug_sub "PARSE: Setting status to '0'."
        mock_output="${mock_status}"
        mock_status=0
      fi

      steps_debug_sub "PARSE: FINISHED"
      steps_debug_sub "       command     : '${command_binary}'"
      steps_debug_sub "       args        : '${command_args}'"
      steps_debug_sub "       status      : '${mock_status}'"
      steps_debug_sub "       output      : '${mock_output}'"
      steps_debug_sub "       side_effect : '${mock_side_effect}'"

      ##
      ## Processing the command.
      ##

      # Track the index of the command call per binary.
      command_index=${command_indexes[${command_binary}]:-1}
      steps_debug_sub "Command index for '${command_binary}' is '${command_index}'."

      if [[ ${phase} == "${PHASE_SETUP}" ]]; then
        # Get mock from passed array or create a new one.
        if [[ -z ${mocked_commands["${command_binary}"]-} ]]; then
          mock=$(mock_command "${command_binary}")
          mocked_commands["${command_binary}"]=${mock}
          steps_debug_sub "SETUP: Created new mock for '${command_binary}' with value '${mocked_commands[${command_binary}]}'."
        else
          mock="${mocked_commands["${command_binary}"]}"
          steps_debug_sub "SETUP: Using existing mock for '${command_binary}' with value '${mocked_commands[${command_binary}]}'."
        fi

        steps_debug_sub "SETUP: Setting mock status to '${mock_status}'."
        mock_set_status "${mock}" "${mock_status}" "${command_index}"

        if [[ -n ${mock_output} ]]; then
          steps_debug_sub "SETUP: Setting mock output to '${mock_output}'."
          mock_set_output "${mock}" "${mock_output}" "${command_index}"
        fi

        if [[ -n ${mock_side_effect} ]]; then
          steps_debug_sub "SETUP: Setting mock side effect to '${mock_side_effect}'."
          mock_set_side_effect "${mock}" "${mock_side_effect}" "${command_index}"
        fi

        steps_debug_sub "SETUP: Setup mock for binary '${command_binary}' complete."
      else
        # Check if mock for the binary exists in the assert phase.
        if [[ -z ${mocked_commands["${command_binary}"]-} ]]; then
          flunk "ERROR: Mock for the binary '${command_binary}' does not exist."
          return 1
        fi

        steps_debug_sub "ASSERT: Found mock for '${command_binary}' with value '${mocked_commands[${command_binary}]}'"

        local mock_args_actual
        mock="${mocked_commands[${command_binary}]}"
        steps_debug_sub "        command     : ${command_binary}"
        steps_debug_sub "        args        : ${command_args}"
        steps_debug_sub "        mock        : ${mock}"
        steps_debug_sub "        index       : ${command_index}"
        if ! mock_args_actual="$(mock_get_call_args "${mock}" "${command_index}" 2>/dev/null)"; then
          flunk "ERROR: Mocked command '${command_binary}' was expected to be called at least ${command_index} time(s), but was called fewer times."
          return 1
        fi
        steps_debug_sub "        actual args : ${mock_args_actual}"

        # Use wildcard-aware assertion.
        if ! mock_assert_call_args "${mock}" "${command_args}" "${command_index}"; then
          flunk "ERROR: Mocked command '${command_binary}' was called with arguments '${mock_args_actual}', but '${command_args}' was expected."
          return 1
        fi
      fi

      command_indexes["${command_binary}"]=$((command_index + 1))
      steps_debug "Updated command index for '${command_binary}' to '${command_indexes[${command_binary}]}'"

    ##
    ## String absent.
    ##
    elif [[ ${item} == "-"* ]]; then
      steps_debug "Type: string absent"

      if [[ ${phase} == "${PHASE_ASSERT}" ]]; then
        assert_output_not_contains "${item:2}" || return 1 # Skip '-' and a space.
      fi
    ##
    ## String present.
    ##
    else
      steps_debug "Type: string present"

      if [[ ${phase} == "${PHASE_ASSERT}" ]]; then
        assert_output_contains "${item}" || return 1
      fi
    fi

    steps_debug "STEP FINISH: '${item}'"
    steps_debug
  done

  # Return mocked commands as a string to pass it to the next phase.
  if [[ ${phase} == "${PHASE_SETUP}" ]]; then
    local mc_string=""
    local key
    for key in "${!mocked_commands[@]}"; do
      mc_string+="${key}=${mocked_commands[${key}]}"$'\n'
    done
    echo "${mc_string}"
  fi
}

##
# Prints a debug message for a step.
#
# Arguments:
#   1. message: Message to print. Optional.
##
steps_debug() {
  steps_debug_write "  > " "${1-}"
}

##
# Prints a debug message for a sub-step.
#
# Arguments:
#   1. message: Message to print. Optional.
##
steps_debug_sub() {
  steps_debug_write "  >   " "${1-}"
}

##
# Prints a debug message to file descriptor 3, shown by 'bats --tap'.
#
# Arguments:
#   1. prefix: Prefix to print before the message.
#   2. message: Message to print.
#
# Globals:
#   RUN_STEPS_DEBUG: Set to '1' to enable debug output.
##
steps_debug_write() {
  if [ "${RUN_STEPS_DEBUG-}" = "1" ]; then
    echo "${1}${2}" >&3
  fi
}

##
## Deprecated aliases, removed in the next version.
##

run_steps() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'run_steps' will be removed in the next version. Use 'steps_run' instead." >&3
  steps_run "$@"
}
