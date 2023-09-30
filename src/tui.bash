#!/usr/bin/env bash
#
# A Bats helper library for working with Terminal User Interface (TUI).
#

tui_run() {
  local answers=("${@}")
  local input

  [ -z "${SCRIPT_FILE-}" ] && echo "SCRIPT_FILE is not set." && exit 1
  [ ! -f "${SCRIPT_FILE}" ] && echo "SCRIPT_FILE does not exist." && exit 1

  for i in "${answers[@]}"; do
    val="${i}"
    [ "${i}" = "nothing" ] && val='\n' || val="${val}"'\n'
    input="${input-}""${val}"
  done

  run bash -c "printf '${input}' | ./${SCRIPT_FILE}"
}
