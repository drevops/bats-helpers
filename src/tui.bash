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
#   SCRIPT_FILE: Path to the script to run. Relative paths resolve against the
#     current directory.
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

  local answers=("$@")
  local input=""
  local i
  local val

  for i in "${answers[@]}"; do
    val="${i}"
    [ "${i}" = "nothing" ] && val=""
    input="${input}${val}"$'\n'
  done

  # A bare './' would break an absolute path, and omitting it would look up a
  # relative one on PATH.
  local script_path="${SCRIPT_FILE}"
  [ "${script_path#/}" = "${script_path}" ] && script_path="./${script_path}"

  # The answers and the path are passed as positional parameters rather than
  # interpolated, and written with '%s' rather than '%b', so that an apostrophe,
  # a '%' directive, a backslash escape or a space reaches the script literally.
  run bash -c 'printf "%s" "$1" | "$2"' _ "${input}" "${script_path}"
}
