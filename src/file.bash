#!/usr/bin/env bash
##
# @file
# Utilities for working with files.
#

mktouch() {
  local file="${1}"
  mkdir -p "$(dirname "${file}")" && touch "${file}"
}

# Trim the last line of the file.
trim_file() {
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  sed_opts+=(-e '$ d')
  sed "${sed_opts[@]}" "${1}"
}

read_env() {
  local t
  # shellcheck disable=SC1090,SC1091
  [ -f "./.env" ] && t=$(mktemp) && export -p >"${t}" && set -a && . "./.env" && set +a && . "${t}" && rm "${t}" && unset t

  # shellcheck disable=SC2294
  eval echo "$@"
}

# Resolve the backup location of a file.
#
# Backups are stored under BATS_HELPERS_BACKUP_DIR, which defaults to a
# directory within the per-test temporary directory so that BATS removes them
# with the rest of the test sandbox. The source path is mirrored below the root
# so that backups of different files do not collide. Paths with a parent
# directory reference are rejected, as they resolve outside of that root.
file_backup_path() {
  local file="${1}"

  case "/${file}/" in
    */../*)
      format_error "Unable to resolve the backup path: file ${file} contains a parent directory reference" | flunk
      return 1
      ;;
  esac

  local root="${BATS_HELPERS_BACKUP_DIR:-${BATS_TEST_TMPDIR:+${BATS_TEST_TMPDIR}/bats-helpers-backup}}"

  if [ -z "${root}" ]; then
    format_error "Unable to resolve the backup directory: BATS_TEST_TMPDIR is not set. Set BATS_HELPERS_BACKUP_DIR to a writable directory" | flunk
    return 1
  fi

  echo "${root%/}/${file#/}"
}

add_var_to_file() {
  local file="${1}"
  local name="${2}"
  local value="${3}"

  if [ ! -f "${file}" ]; then
    format_error "File ${file} does not exist" | flunk
    return 1
  fi

  local backup
  backup="$(file_backup_path "${file}")" || return 1

  mkdir -p "$(dirname "${backup}")" || return 1
  cp -f "${file}" "${backup}" || return 1

  echo "${name}=${value}" >>"${file}"
}

restore_file() {
  local file="${1}"

  local backup
  backup="$(file_backup_path "${file}")" || return 1

  if [ ! -f "${backup}" ]; then
    format_error "Backup for file ${file} does not exist" | flunk
    return 1
  fi

  cp -f "${backup}" "${file}"
}
