#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2294

assert_file_exists() {
  local file="${1}"

  for f in ${file}; do
    if [ -e "$f" ]; then
      return 0
    else
      format_error "File ${file} does not exist" | flunk
    fi
    ## This is all we needed to know, so we can break after the first iteration.
    break
  done

  format_error "File ${file} does not exist" | flunk
}

assert_file_not_exists() {
  local file="${1}"

  for f in ${file}; do
    if [ -e "$f" ]; then
      format_error "File ${file} exists, but should not" | flunk
    else
      return 0
    fi
  done
}

assert_dir_exists() {
  local dir="${1}"

  if [ -d "${dir}" ]; then
    return 0
  else
    format_error "Directory ${dir} does not exist" | flunk
  fi
}

assert_dir_not_exists() {
  local dir="${1:-$(pwd)}"

  if [ -d "${dir}" ]; then
    format_error "Directory ${dir} exists, but should not" | flunk
  else
    return 0
  fi
}

assert_dir_empty() {
  local dir="${1:-$(pwd)}"
  assert_dir_exists "${dir}" || return 1

  if [ "$(ls -A "${dir}")" ]; then
    format_error "Directory ${dir} is not empty, but should be" | flunk
  else
    return 0
  fi
}

assert_dir_not_empty() {
  local dir="${1:-$(pwd)}"
  assert_dir_exists "${dir}"

  if [ "$(ls -A "${dir}")" ]; then
    return 0
  else
    format_error "Directory ${dir} is empty, but should not be" | flunk
  fi
}

assert_symlink_exists() {
  local file="${1}"

  if [ ! -h "${file}" ] && [ -f "${file}" ]; then
    format_error "Regular file ${file} exists, but symlink is expected" | flunk
  elif [ ! -h "${file}" ]; then
    format_error "Symlink ${file} does not exist" | flunk
  else
    return 0
  fi
}

assert_symlink_not_exists() {
  local file="${1}"

  if [ ! -h "${file}" ] && [ -f "${file}" ]; then
    return 0
  elif [ ! -h "${file}" ]; then
    return 0
  else
    format_error "Symlink ${file} exists, but should not" | flunk
  fi
}

assert_file_mode() {
  local file="${1}"
  local perm="${2}"
  assert_file_exists "${file}"

  if [ "$(uname)" = "Darwin" ]; then
    parsed=$(printf "%.3o\n" $(($(stat -f '0%Lp' "$file") & ~0022)))
  else
    parsed=$(printf "%.3o\n" $(($(stat --printf '0%a' "$file") & ~0022)))
  fi

  if [ "${parsed}" != "${perm}" ]; then
    format_error "File permissions for file ${file} is '${parsed}', but expected '${perm}'" | flunk
  else
    return 0
  fi
}

assert_file_contains() {
  local file="${1}"
  local string="${2}"
  assert_file_exists "${file}"

  contents="$(cat "${file}")"
  assert_contains "${string}" "${contents}"
}

assert_file_not_contains() {
  local file="${1}"
  local string="${2}"

  [ ! -f "${file}" ] && return 0

  contents="$(cat "${file}")"
  assert_not_contains "${string}" "${contents}"
}

assert_dir_contains_string() {
  local dir="${1}"
  local string="${2}"

  assert_dir_exists "${dir}" || return 1

  if grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" --exclude-dir=".data" -l "${string}" "${dir}"; then
    return 0
  else
    format_error "Directory ${dir} does not contain a string '${string}'" | flunk
  fi
}

assert_dir_not_contains_string() {
  local dir="${1}"
  local string="${2}"

  [ ! -d "${dir}" ] && return 0

  if grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" --exclude-dir=".data" -l "${string}" "${dir}"; then
    format_error "Directory ${dir} contains string '${string}', but should not" | flunk
  else
    return 0
  fi
}

assert_files_equal() {
  local file1="${1}"
  local file2="${2}"
  local ignore_spaces="${3:-0}"

  diff_opts=()
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if diff "${diff_opts[@]}" "${file1}" "${file2}"; then
    return 0
  else
    format_error "File ${file1} is not equal to file ${file2}" | flunk
  fi
}

assert_files_not_equal() {
  local file1="${1}"
  local file2="${2}"
  local ignore_spaces="${3:-0}"

  diff_opts=()
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if diff "${diff_opts[@]}" "${file1}" "${file2}"; then
    format_error "File ${file1} is equal to file ${file2}, but it should not be" | flunk
  else
    return 0
  fi
}

assert_binary_files_equal() {
  local file1="${1}"
  local file2="${2}"

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if cmp "${file1}" "${file2}"; then
    return 0
  else
    format_error "File ${file1} is not equal to file ${file2}" | flunk
  fi
}

assert_binary_files_not_equal() {
  local file1="${1}"
  local file2="${2}"

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if cmp "${file1}" "${file2}"; then
    format_error "File ${file1} is equal to file ${file2}, but it should not be" | flunk
  else
    return 0
  fi
}

assert_dirs_equal() {
  local dir1="${1}"
  local dir2="${2}"

  assert_dir_exists "${dir1}" || return 1
  assert_dir_exists "${dir2}" || return 1

  for file in $(find "${dir1}/" -type f); do
    assert_binary_files_equal "${file}" "${file/${dir1}/${dir2}}" || return 1
  done

  for file in $(find "${dir2}/" -type f); do
    assert_binary_files_equal "${file}" "${file/${dir2}/${dir1}}" || return 1
  done

  return 0
}

# Trim the last line of the file.
trim_file() {
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  sed_opts+=(-e '$ d')
  sed "${sed_opts[@]}" "${1}"
}

read_env() {
  # shellcheck disable=SC1090,SC1091
  [ -f "./.env" ] && t=$(mktemp) && export -p >"$t" && set -a && . "./.env" && set +a && . "$t" && rm "$t" && unset t

  eval echo "${@}"
}

add_var_to_file() {
  local file="${1}"
  local name="${2}"
  local value="${3}"

  local backup=/tmp/bkp/"${file}"
  mkdir -p "$(dirname "${backup}")"

  cp -f "${file}" "${backup}"

  # shellcheck disable=SC2086
  echo $name=$value >>"${file}"
}

restore_file() {
  local file="${1}"
  local backup=/tmp/bkp/"${file}"

  cp -f "${backup}" "${file}"
}

mktouch() {
  local file="${1}"
  mkdir -p "$(dirname "${file}")" && touch "${file}"
}
