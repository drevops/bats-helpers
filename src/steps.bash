#!/usr/bin/env bash

################################################################################
# Setup and process a sequence of string and mocked command assertions.
#
# Global variables:
# - STEPS: An array holding the steps to be processed.
# - RUN_STEPS_DEBUG: Set to '1' to enable debug output.
#
# Parameters:
# 1. Phase: Either "setup" or "assert". Defaults to "assert".
# 2. Mocked Commands (optional for 'setup', required for 'assert' phase):
#    An array holding the mocked command details.
#
# Return:
#  The mocked commands array for the 'setup' phase.
#
#
# Usage:
# When used with commands, this function needs to be called twice, once for
# the 'setup' phase and once for the 'assert' phase. The 'setup' phase will mock
# the commands and the 'assert' phase will assert the commands.
# When used with strings, just call it once for the 'assert' phase.
#
# STEPS=(...)
# mocks="$(run_steps "setup")" # $mocks will hold created mocks
# # ... code to be tested ...
# run_steps "assert" "$mocks"
#
# Every step is a string that can be one of the following:
# @<command> [<args>] # <mock_status> [ # <mock_output> [ # <mock_side_effect> ]]
#   Mock the command <command> with the given status, optional output, and optional side effect.
#   Status can be omitted and <mock_output> can be used instead.
#   Side effect is Bash code that will be executed when the mock is called.
#   Different commands can be mocked multiple times.
#   Call to the same command will be using the same mock.
#   If <args> contains literal '#' characters (e.g., in URLs like https://example.com#anchor),
#   escape them as '\#' to prevent them from being treated as delimiters.
#
# <substring>
#   Check that the output contains the given substring.
#
# - <substring>
#   Ensure the output does NOT contain the specified substring.
#   Starts with '- ' (minus followed by space).
#
# Example:
# declare -a STEPS=(
#   # Mock `drush` binary with an exit status of 1 and not output.
#   "@drush -y status --field=drupal-version # 1"
#   # Mock `drush` binary with an exit status of 0 and output "success".
#   "@drush -y status --fields=bootstrap # success"
#   # Mock `drush` binary with an exit status of 1 and output "failure".
#   "@drush -y status --fields=bootstrap # 1 # failure"
#   # Mock `drush` binary with side effect that creates a file.
#   "@drush cache-rebuild # 0 # Cache rebuilt # touch /tmp/cache-cleared"
#   # Mock command with URL containing hash fragment (escaped as \#).
#   "@curl -fsSL https://example.com\#anchor -o file.php # 0"
#   "@git clone https://github.com/user/repo.git\#stable # 0 # Cloning repo"
#   # Assert presence of the partial string in the output "Hello world"
#   "Hello world"
#   # Assert absence of the partial string in the output "Goodbye world"
#   "- Goodbye world"
# )
#
# mocks="$(run_steps "setup")" # $mocks will hold created mocks
# # ... code to be tested ...
# run_steps "assert" "$mocks" # Assertions will be processed.
#
################################################################################
run_steps() {
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

  # Create associative array for mocked commands
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

    #########################################################################
    #                                COMMAND                                #
    #########################################################################
    if [[ ${item} == "@"* ]]; then
      steps_debug "Type: command"
      steps_debug

      #------------------------------------------------------------------------
      # Parsing the command, status, and optional output.
      #------------------------------------------------------------------------

      steps_debug_sub "PARSE: STARTED"

      # Replace escaped hashes with a placeholder before parsing
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

      # Restore escaped hashes in all parsed components
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

      #------------------------------------------------------------------------
      # Processing the command.
      #------------------------------------------------------------------------

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
        # Check if mock for the binary exists in the assert phase
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

        # Use wildcard-aware assertion
        if ! mock_assert_call_args "${mock}" "${command_args}" "${command_index}"; then
          flunk "ERROR: Mocked command '${command_binary}' was called with arguments '${mock_args_actual}', but '${command_args}' was expected."
          return 1
        fi
      fi

      command_indexes["${command_binary}"]=$((command_index + 1))
      steps_debug "Updated command index for '${command_binary}' to '${command_indexes[${command_binary}]}'"

    #########################################################################
    #                            STRING ABSENT                              #
    #########################################################################
    elif [[ ${item} == "-"* ]]; then
      steps_debug "Type: string absent"

      if [[ ${phase} == "${PHASE_ASSERT}" ]]; then
        assert_output_not_contains "${item:2}" || return 1 # Skip '-' and a space.
      fi
    #########################################################################
    #                            STRING PRESENT                             #
    #########################################################################
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
# Print a debug message for a step.
#
# Parameters:
# 1. Message. Optional.
##
steps_debug() {
  steps_debug_write "  > " "${1-}"
}

##
# Print a debug message for a sub-step.
#
# Parameters:
# 1. Message. Optional.
##
steps_debug_sub() {
  steps_debug_write "  >   " "${1-}"
}

##
# Print a debug message to the file descriptor 3, shown by `bats --tap`.
#
# Global variables:
# - RUN_STEPS_DEBUG: Set to '1' to enable debug output.
#
# Parameters:
# 1. Prefix.
# 2. Message.
##
steps_debug_write() {
  if [ "${RUN_STEPS_DEBUG-}" = "1" ]; then
    echo "${1}${2}" >&3
  fi
}
