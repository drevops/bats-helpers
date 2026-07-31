#!/usr/bin/env bash
##
# @file
# Utilities for working with files.
#

##
# Creates a file and any missing parent directories.
#
# Arguments:
#   1. file: Path to create.
##
mktouch() {
  local file="${1}"
  mkdir -p "$(dirname "${file}")" && touch "${file}"
}

##
# Removes the last line of a file in place.
#
# Arguments:
#   1. file: File to trim.
##
trim_file() {
  local sed_opts

  if [ "$(uname)" = "Darwin" ]; then
    sed_opts=(-i '')
  else
    sed_opts=(-i)
  fi

  sed_opts+=(-e '$ d')
  sed "${sed_opts[@]}" "${1}"
}

##
# Evaluates an expression with the variables from the '.env' file in scope.
#
# The variables are visible only for the duration of the call: the caller's
# environment is captured beforehand and restored afterwards.
#
# Arguments:
#   1. expression: Expression to evaluate.
#
# Outputs:
#   STDOUT: The evaluated expression.
##
read_env() {
  local t
  # shellcheck disable=SC1090,SC1091
  [ -f "./.env" ] && t=$(mktemp) && export -p >"${t}" && set -a && . "./.env" && set +a && . "${t}" && rm "${t}" && unset t

  # shellcheck disable=SC2294
  eval echo "$@"
}

##
# Resolves the backup location of a file.
#
# The source path is mirrored below the backup root so that backups of
# different files do not collide. Paths with a parent directory reference are
# rejected, as they resolve outside of that root.
#
# Arguments:
#   1. file: File whose backup path to resolve.
#
# Globals:
#   BATS_HELPERS_BACKUP_DIR: Backup root. Defaults to a directory within the
#     per-test temporary directory, so that BATS removes the backups with the
#     rest of the test sandbox.
#
# Outputs:
#   STDOUT: The backup path.
##
file_backup_path() {
  local file="${1}"

  case "/${file}/" in
    */../*)
      format_error "Unable to resolve the backup path: file '${file}' contains a parent directory reference" | flunk
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

##
# Appends a variable assignment to a file, backing the file up first.
#
# Arguments:
#   1. file: File to append to.
#   2. name: Variable name.
#   3. value: Variable value.
##
add_var_to_file() {
  local file="${1}"
  local name="${2}"
  local value="${3}"

  if [ ! -f "${file}" ]; then
    format_error "File '${file}' does not exist" | flunk
    return 1
  fi

  local backup
  backup="$(file_backup_path "${file}")" || return 1

  mkdir -p "$(dirname "${backup}")" || return 1
  cp -f "${file}" "${backup}" || return 1

  echo "${name}=${value}" >>"${file}"
}

##
# Restores a file from the backup taken by 'add_var_to_file'.
#
# Arguments:
#   1. file: File to restore.
##
restore_file() {
  local file="${1}"

  local backup
  backup="$(file_backup_path "${file}")" || return 1

  if [ ! -f "${backup}" ]; then
    format_error "Backup for file '${file}' does not exist" | flunk
    return 1
  fi

  cp -f "${backup}" "${file}"
}
