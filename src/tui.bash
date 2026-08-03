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
#   BATS_HELPERS_SCRIPT_FILE: Path to the script to run, relative to the
#     current directory.
##
tui_run() {
  local script_file
  if [ -n "${BATS_HELPERS_SCRIPT_FILE-}" ]; then
    script_file="${BATS_HELPERS_SCRIPT_FILE}"
  elif [ -n "${SCRIPT_FILE-}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'SCRIPT_FILE' will be removed in the next version. Use 'BATS_HELPERS_SCRIPT_FILE' instead." >&3
    script_file="${SCRIPT_FILE}"
  else
    flunk "BATS_HELPERS_SCRIPT_FILE is not set."
    return 1
  fi

  if [ ! -e "${script_file}" ]; then
    flunk "Script file '${script_file}' does not exist."
    return 1
  fi

  if [ ! -f "${script_file}" ]; then
    flunk "Script file '${script_file}' is not a regular file."
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

  # The answers and the path are passed as positional parameters rather than
  # interpolated, so that an apostrophe, a '%' directive or a space in either
  # reaches the script literally.
  run bash -c 'printf "%b" "$1" | "./$2"' _ "${input}" "${script_file}"
}
