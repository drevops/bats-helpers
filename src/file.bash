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
file_mktouch() {
  local file="${1}"
  mkdir -p "$(dirname "${file}")" && touch "${file}"
}

##
# Removes the last line of a file in place.
#
# Arguments:
#   1. file: File to trim.
##
file_trim() {
  local -a sed_opts

  if [ "$(uname)" = "Darwin" ]; then
    sed_opts=(-i '')
  else
    sed_opts=(-i)
  fi

  sed_opts+=(-e '$ d')
  sed "${sed_opts[@]}" "${1}"
}

##
# Evaluates an expression with the variables from the './.env' file in scope.
#
# Variables that were already exported are restored to their previous values
# once the expression has been evaluated. Variables that './.env' introduces
# stay exported.
#
# Arguments:
#   1. expression: Expression to evaluate.
#
# Globals:
#   BATS_TEST_TMPDIR: Per-test sandbox the snapshot of exported variables is
#     written to.
#
# Outputs:
#   STDOUT: The evaluated expression.
##
file_read_env() {
  local t
  # The snapshot lives in the per-test sandbox so that bats removes it even when
  # the restore below never runs.
  # shellcheck disable=SC1090,SC1091
  [ -f "./.env" ] && t="$(mktemp "${BATS_TEST_TMPDIR}/bats-helpers-env.XXXXXX")" && export -p >"${t}" && set -a && . "./.env" && set +a && . "${t}" && rm "${t}" && unset t

  # shellcheck disable=SC2294
  eval echo "$@"
}

##
# Resolves the backup location of a file.
#
# The source path is mirrored below the backup root, so files in different
# directories keep separate backups. A leading slash is stripped, so relative
# and absolute paths to the same location share one backup. Paths with a parent
# directory reference are rejected, as they resolve outside of that root.
#
# Arguments:
#   1. file: File whose backup path to resolve.
#
# Globals:
#   BATS_HELPERS_FILE_BACKUP_DIR: Backup root. Defaults to a directory within
#     the per-test temporary directory, so that BATS removes the backups with
#     the rest of the test sandbox.
#   BATS_HELPERS_BACKUP_DIR: Deprecated name of the above.
#   BATS_TEST_TMPDIR: Per-test sandbox, used when no directory is set.
#   BATS_HELPERS_DEPRECATION_QUIET: Non-empty suppresses this library's
#     deprecation notices.
#
# Outputs:
#   STDOUT: The backup path.
##
file_backup_path() {
  local file="${1}"

  case "/${file}/" in
    */../*)
      flunk "Unable to resolve the backup path: file '${file}' contains a parent directory reference."
      return 1
      ;;
  esac

  local root
  if [ -n "${BATS_HELPERS_FILE_BACKUP_DIR-}" ]; then
    root="${BATS_HELPERS_FILE_BACKUP_DIR}"
  elif [ -n "${BATS_HELPERS_BACKUP_DIR-}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'BATS_HELPERS_BACKUP_DIR' will be removed in the next version. Use 'BATS_HELPERS_FILE_BACKUP_DIR' instead." >&3
    root="${BATS_HELPERS_BACKUP_DIR}"
  else
    root="${BATS_TEST_TMPDIR:+${BATS_TEST_TMPDIR}/bats-helpers-backup}"
  fi

  if [ -z "${root}" ]; then
    flunk "Unable to resolve the backup directory: 'BATS_TEST_TMPDIR' is not set. Set BATS_HELPERS_FILE_BACKUP_DIR to a writable directory."
    return 1
  fi

  printf '%s\n' "${root%/}/${file#/}"
}

##
# Appends a variable assignment to a file, backing the file up first.
#
# Arguments:
#   1. file: File to append to.
#   2. name: Variable name.
#   3. value: Variable value.
##
file_add_var() {
  local file="${1}"
  local name="${2}"
  local value="${3}"

  if [ ! -f "${file}" ]; then
    format_error "File does not exist" "file" "${file}" | flunk
    return 1
  fi

  local backup
  backup="$(file_backup_path "${file}")" || return 1

  mkdir -p "$(dirname "${backup}")" || return 1
  cp -f "${file}" "${backup}" || return 1

  printf '%s\n' "${name}=${value}" >>"${file}"
}

##
# Restores a file from the backup taken by 'file_add_var'.
#
# Arguments:
#   1. file: File to restore.
##
file_restore() {
  local file="${1}"

  local backup
  backup="$(file_backup_path "${file}")" || return 1

  if [ ! -f "${backup}" ]; then
    format_error "Backup does not exist" "file" "${file}" "backup" "${backup}" | flunk
    return 1
  fi

  cp -f "${backup}" "${file}"
}

##
## Deprecated aliases, removed in the next version.
##

mktouch() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'mktouch' will be removed in the next version. Use 'file_mktouch' instead." >&3
  file_mktouch "$@"
}

trim_file() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'trim_file' will be removed in the next version. Use 'file_trim' instead." >&3
  file_trim "$@"
}

read_env() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'read_env' will be removed in the next version. Use 'file_read_env' instead." >&3
  file_read_env "$@"
}

add_var_to_file() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'add_var_to_file' will be removed in the next version. Use 'file_add_var' instead." >&3
  file_add_var "$@"
}

restore_file() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'restore_file' will be removed in the next version. Use 'file_restore' instead." >&3
  file_restore "$@"
}
