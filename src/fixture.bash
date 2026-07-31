#!/usr/bin/env bash
#
# A Bats helper library for working with fixtures.
#

#
# Export codebase source code at the latest commit to the destination directory.
#
fixture_export_codebase() {
  if [ "${BATS_FIXTURE_EXPORT_CODEBASE_ENABLED-}" != "1" ]; then
    return
  fi

  local dst="${1?Destination directory is required}"
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
    flunk "Failed to export codebase from ${src} to ${dst}."
    return 1
  fi
}

#
# Prepare a directory for a fixture.
#
fixture_prepare_dir() {
  local dir="${1:-"$(pwd)"}"
  rm -Rf "${dir}" >/dev/null
  mkdir -p "${dir}"
  assert_dir_exists "${dir}"
}
