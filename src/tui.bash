#!/usr/bin/env bash
#
# A Bats helper library for working with Terminal User Interface (TUI).
#

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
