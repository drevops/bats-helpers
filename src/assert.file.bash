#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2086

assert_file_exists() {
  local file="${1}"
  local f

  for f in ${file}; do
    if [ -e "${f}" ]; then
      return 0
    else
      format_error "File '${file}' does not exist" | flunk
    fi
    ## This is all we needed to know, so we can break after the first iteration.
    break
  done

  format_error "File '${file}' does not exist" | flunk
}

assert_file_not_exists() {
  local file="${1}"
  local f

  for f in ${file}; do
    if [ -e "${f}" ]; then
      format_error "File '${file}' exists, but should not" | flunk
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
    format_error "Directory '${dir}' does not exist" | flunk
  fi
}

assert_dir_not_exists() {
  local dir="${1:-$(pwd)}"

  if [ -d "${dir}" ]; then
    format_error "Directory '${dir}' exists, but should not" | flunk
  else
    return 0
  fi
}

assert_dir_empty() {
  local dir="${1:-$(pwd)}"
  assert_dir_exists "${dir}" || return 1

  if [ "$(ls -A "${dir}")" ]; then
    format_error "Directory '${dir}' is not empty" | flunk
  else
    return 0
  fi
}

assert_dir_not_empty() {
  local dir="${1:-$(pwd)}"
  assert_dir_exists "${dir}" || return 1

  if [ "$(ls -A "${dir}")" ]; then
    return 0
  else
    format_error "Directory '${dir}' is empty, but should not be" | flunk
  fi
}

assert_symlink_exists() {
  local file="${1}"

  if [ ! -h "${file}" ] && [ -f "${file}" ]; then
    format_error "Regular file '${file}' exists, but should be a symlink" | flunk
  elif [ ! -h "${file}" ]; then
    format_error "Symlink '${file}' does not exist" | flunk
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
    format_error "Symlink '${file}' exists, but should not" | flunk
  fi
}

assert_file_mode() {
  local file="${1}"
  local perm="${2}"
  local parsed
  assert_file_exists "${file}" || return 1

  if [ "$(uname)" = "Darwin" ]; then
    parsed=$(printf "%.3o\n" $(($(stat -f '0%Lp' "$file") & ~0022)))
  else
    parsed=$(printf "%.3o\n" $(($(stat --printf '0%a' "$file") & ~0022)))
  fi

  if [ "${parsed}" != "${perm}" ]; then
    format_error "File '${file}' has permissions '${parsed}', but should have '${perm}'" | flunk
  else
    return 0
  fi
}

assert_file_contains() {
  local file="${1}"
  local string="${2}"
  assert_file_exists "${file}" || return 1

  local contents
  contents="$(cat "${file}")"
  assert_string_contains "${contents}" "${string}"
}

assert_file_not_contains() {
  local file="${1}"
  local string="${2}"

  [ ! -f "${file}" ] && return 0

  local contents
  contents="$(cat "${file}")"
  assert_string_not_contains "${contents}" "${string}"
}

assert_dir_contains_string() {
  local dir="${1}"
  local string="${2}"
  local default_exclude_dirs=(".git" ".idea" "vendor" "node_modules")

  assert_dir_exists "${dir}" || return 1

  local exclude_params=""
  local exclude_dir
  for exclude_dir in "${default_exclude_dirs[@]}" "${ASSERT_DIR_EXCLUDE[@]-}"; do
    [ -n "${exclude_dir}" ] && exclude_params+="--exclude-dir=${exclude_dir} "
  done

  if grep -rI ${exclude_params} -l "${string}" "${dir}"; then
    return 0
  else
    format_error "Directory '${dir}' does not contain string '${string}'" | flunk
  fi
}

assert_dir_not_contains_string() {
  local dir="${1}"
  local string="${2}"
  local default_exclude_dirs=(".git" ".idea" "vendor" "node_modules")

  [ ! -d "${dir}" ] && return 0

  local exclude_params=""
  local exclude_dir
  for exclude_dir in "${default_exclude_dirs[@]}" "${ASSERT_DIR_EXCLUDE[@]-}"; do
    [ -n "${exclude_dir}" ] && exclude_params+="--exclude-dir=${exclude_dir} "
  done

  if grep -rI ${exclude_params} -l "${string}" "${dir}"; then
    format_error "Directory '${dir}' contains string '${string}', but should not" | flunk
  else
    return 0
  fi
}

assert_files_equal() {
  local file1="${1}"
  local file2="${2}"
  local ignore_spaces="${3:-0}"

  local diff_opts=(--normal)
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if diff "${diff_opts[@]}" "${file1}" "${file2}"; then
    return 0
  else
    format_error "File '${file1}' is not equal to file '${file2}'" | flunk
  fi
}

assert_files_not_equal() {
  local file1="${1}"
  local file2="${2}"
  local ignore_spaces="${3:-0}"

  local diff_opts=(--normal)
  [ "${ignore_spaces}" = 1 ] && diff_opts+=(-B -b)

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if diff "${diff_opts[@]}" "${file1}" "${file2}"; then
    format_error "File '${file1}' is equal to file '${file2}', but should not be" | flunk
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
    format_error "File '${file1}' is not equal to file '${file2}'" | flunk
  fi
}

assert_binary_files_not_equal() {
  local file1="${1}"
  local file2="${2}"

  assert_file_exists "${file1}" || return 1
  assert_file_exists "${file2}" || return 1

  if cmp "${file1}" "${file2}"; then
    format_error "File '${file1}' is equal to file '${file2}', but should not be" | flunk
  else
    return 0
  fi
}

assert_dirs_equal() {
  local dir1="${1}"
  local dir2="${2}"
  local file

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
