#!/usr/bin/env bash
# Fixture script to test TUI prompts and deadlines.
# LCOV_EXCL_START
set -e

ask() {
  local prompt="$1"
  local default="${2-}"

  # Printed rather than passed to 'read -p', which shows nothing when STDIN is
  # not a terminal, and printed outside a command substitution so that it
  # reaches the output instead of being captured.
  printf '%s [%s]: \n' "${prompt}" "${default}"

  answer=""

  # An unanswered prompt waits rather than giving up at EOF, the way a script
  # reading from a terminal does.
  while ! read -r answer; do
    sleep 0.1
  done

  [ -n "${answer}" ] || answer="${default}"
}

echo "Static script output"

ask "Answer1" "default answer1"
answer1="${answer}"

ask "Answer2" "default answer2"
answer2="${answer}"

echo "${answer1}"
echo "${answer2}"
# LCOV_EXCL_STOP
