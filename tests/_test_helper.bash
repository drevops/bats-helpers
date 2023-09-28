#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2294

# Load library.
load '../load.bash'

setup() {
  # Setup command mocking.
  setup_mock
}

prepare_fixture_dir() {
  local dir="${1:-$(pwd)}"
  rm -Rf "${dir}" >/dev/null
  mkdir -p "${dir}"
  assert_dir_exists "${dir}"
}
