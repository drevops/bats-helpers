#!/usr/bin/env bash
# Fixture script to test mocking.
# LCOV_EXCL_START
set -e

ask() {
  local prompt="$1"
  local default="${2-}"
  local result=""

  if [[ -n $default ]]; then
    prompt="${prompt} [${default}]: "
  else
    prompt="${prompt}: "
  fi

  while [[ -z ${result} ]]; do
    read -r -p "${prompt}" result
    if [[ -n $default && -z ${result} ]]; then
      result="${default}"
    fi
  done

  echo "${result}"
}

echo "Static script output"

answer1="$(ask "Answer1" "default answer1")"
answer2="$(ask "Answer2" "default answer2")"

echo "${answer1}"
echo "${answer2}"
