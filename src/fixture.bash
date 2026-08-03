#!/usr/bin/env bash
##
# @file
# Utilities for preparing test fixtures.
#

##
# Exports the codebase at the latest commit to a destination directory.
#
# Arguments:
#   1. dst: Destination directory. Required.
#   2. src: Repository to export. Optional, defaults to the current directory.
#
# Globals:
#   BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED: Set to '1' to enable the
#     export. Anything else makes this function a no-op.
##
fixture_export_codebase() {
  local enabled
  if [ -n "${BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED-}" ]; then
    enabled="${BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED}"
  elif [ -n "${BATS_FIXTURE_EXPORT_CODEBASE_ENABLED-}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'BATS_FIXTURE_EXPORT_CODEBASE_ENABLED' will be removed in the next version. Use 'BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED' instead." >&3
    enabled="${BATS_FIXTURE_EXPORT_CODEBASE_ENABLED}"
  fi

  if [ "${enabled-}" != "1" ]; then
    return
  fi

  local dst="${1?Destination directory is required.}"
  local src="${2:-"$(pwd)"}"

  assert_dir_exists "${dst}" || return 1
  assert_git_repo "${src}" || return 1

  local export_status=0

  # The subshell scopes both the working directory and 'pipefail', so a failing
  # 'git archive' surfaces instead of being masked by a successful 'tar'.
  (
    set -o pipefail
    cd "${src}" && git archive --format=tar HEAD | (cd "${dst}" && tar -xf -)
  ) || export_status=$?

  if [ "${export_status}" -ne 0 ]; then
    flunk "Failed to export codebase from '${src}' to '${dst}'."
    return 1
  fi
}

##
# Creates an empty directory for a fixture, removing any existing content.
#
# Arguments:
#   1. dir: Directory to prepare. Optional, defaults to the current directory.
##
fixture_prepare_dir() {
  local dir="${1:-"$(pwd)"}"
  rm -Rf "${dir}" >/dev/null
  mkdir -p "${dir}"
  assert_dir_exists "${dir}"
}
