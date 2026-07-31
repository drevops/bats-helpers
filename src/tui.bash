#!/usr/bin/env bash
##
# @file
# Helpers for testing Terminal User Interface (TUI) scripts.
#

##
# Runs a TUI script, feeding it a list of answers on STDIN.
#
# Each answer is submitted followed by a newline. The literal answer 'nothing'
# submits an empty line, so a prompt can be left at its default.
#
# Arguments:
#   1. answers: Answers to submit, one per argument, in the order the script
#      prompts for them.
#
# Globals:
#   SCRIPT_FILE: Path to the script to run, relative to the current directory.
##
tui_run() {
  if [ -z "${SCRIPT_FILE-}" ]; then
    flunk "SCRIPT_FILE is not set."
    return 1
  fi

  if [ ! -f "${SCRIPT_FILE}" ]; then
    flunk "SCRIPT_FILE does not exist."
    return 1
  fi

  local answers=("$@")
  local input
  local i
  local val

  for i in "${answers[@]}"; do
    val="${i}"
    [ "${i}" = "nothing" ] && val='\n' || val="${val}"'\n'
    input="${input-}""${val}"
  done

  run bash -c "printf '${input}' | ./${SCRIPT_FILE}"
}
