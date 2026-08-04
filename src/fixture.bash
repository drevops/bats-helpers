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

##
## File trees.
##

##
# Creates a file tree from an archive read from STDIN.
#
# An archive is a run of file entries. Each entry opens with a marker line
# naming the file - '-- src/app.sh --' - and holds every line up to the next
# marker, so anything that is not a marker is content and the format has no
# syntax errors. Content before the first marker is a comment and is discarded.
# Parent directories are created implicitly.
#
# The directory is created when it does not exist, and only the files the
# archive names are written, so 'fixture_prepare_dir' is the way to start from
# an empty directory.
#
# Arguments:
#   1. dir: Directory to create the tree in.
##
fixture_create_dir() {
  local dir="${1?Directory is required.}"

  local -a paths=()
  local -a contents=()
  fixture_read_archive || return 1

  if ! mkdir -p "${dir}"; then
    flunk "Unable to create fixture directory '${dir}'."
    return 1
  fi

  local index
  local path
  local target

  for ((index = 0; index < ${#paths[@]}; index++)); do
    path="${paths[index]}"
    target="${dir}/${path}"

    if [ -d "${target}" ]; then
      flunk "Fixture path '${path}' exists as a directory."
      return 1
    fi

    if ! file_mktouch "${target}"; then
      flunk "Unable to create fixture file '${path}'."
      return 1
    fi

    printf '%s' "${contents[index]}" >"${target}"
  done

  return 0
}

##
# Prints a directory as an archive.
#
# Only regular files are serialised, so symlinks, empty directories and file
# modes are not represented. A file that does not end with a newline is printed
# with one, because the format is line-based.
#
# Arguments:
#   1. dir: Directory to serialise.
#
# Outputs:
#   STDOUT: The archive, with the entries ordered by path.
##
fixture_dump_dir() {
  local dir="${1?Directory is required.}"

  assert_dir_exists "${dir}" || return 1

  local listing
  listing="$(fixture_list_files "${dir}")" || return 1

  [ -n "${listing}" ] || return 0

  # A content line that would otherwise be read as a marker, and one already
  # carrying the escape, both take one more backslash.
  local marker_line='^\\*-- .* --$'
  local file
  local line

  while IFS= read -r file; do
    if [ -s "${dir}/${file}" ] && ! LC_ALL=C grep -Iq '^' "${dir}/${file}"; then
      flunk "Fixture file '${file}' is not a text file."
      return 1
    fi

    printf -- '-- %s --\n' "${file}"

    while IFS= read -r line || [ -n "${line}" ]; do
      if [[ ${line} =~ ${marker_line} ]]; then
        line="\\${line}"
      fi

      printf '%s\n' "${line}"
    done <"${dir}/${file}"
  done <<<"${listing}"

  return 0
}

##
# Asserts that a directory holds the file tree of an archive read from STDIN.
#
# Only regular files are compared, and the comparison is byte-exact, so a file
# that does not end with a newline differs from the archive, which always names
# one.
#
# Arguments:
#   1. dir: Directory to compare.
##
fixture_assert_dir() {
  local dir="${1?Directory is required.}"

  assert_dir_exists "${dir}" || return 1

  local -a paths=()
  local -a contents=()
  fixture_read_archive || return 1

  ##
  ## Expected files.
  ##

  # The paths are held as one newline-delimited value so that a path is matched
  # as a whole word without becoming an array subscript.
  local expected=$'\n'
  local summary=""
  local report=""
  local differences=0
  local index
  local path
  local target
  local file_diff

  for ((index = 0; index < ${#paths[@]}; index++)); do
    path="${paths[index]}"
    expected="${expected}${path}"$'\n'
    target="${dir}/${path}"

    if [ ! -f "${target}" ]; then
      summary="${summary}missing: ${path}"$'\n'
      differences=$((differences + 1))
      continue
    fi

    file_diff="$(diff -u -L "expected ${path}" -L "actual ${path}" <(printf '%s' "${contents[index]}") "${target}")" && continue

    summary="${summary}differs: ${path}"$'\n'
    report="${report}${file_diff}"$'\n'
    differences=$((differences + 1))
  done

  ##
  ## Unexpected files.
  ##

  local listing
  listing="$(fixture_list_files "${dir}")" || return 1

  local file
  while IFS= read -r file; do
    [ -n "${file}" ] || continue

    case "${expected}" in
      *$'\n'"${file}"$'\n'*)
        continue
        ;;
    esac

    summary="${summary}unexpected: ${file}"$'\n'
    differences=$((differences + 1))
  done <<<"${listing}"

  ##
  ## Failure report.
  ##

  [ "${differences}" -eq 0 ] && return 0

  local message="Directory '${dir}' does not match the expected fixture"$'\n\n'"${summary%$'\n'}"

  if [ -n "${report}" ]; then
    message="${message}"$'\n\n'"${report%$'\n'}"
  fi

  format_error "${message}" | flunk
}

##
# Reads an archive from STDIN into the caller's entry arrays.
#
# The arrays are resolved through Bash dynamic scoping, so the caller declares
# them as locals and this function fills them in place.
#
# Globals:
#   paths: Array the caller declares, filled with the path of every entry, in
#     the order the entries appear.
#   contents: Array the caller declares, filled with the matching contents.
##
fixture_read_archive() {
  # A content line carrying the escape loses one backslash, so a line that is
  # marker-shaped after the removal is the one to unescape.
  local escaped_marker='^\\+-- .* --$'
  # The declared paths are held as one newline-delimited value so that a path is
  # matched as a whole word without becoming an array subscript.
  local declared=$'\n'
  local index=-1
  local line
  local path

  while IFS= read -r line || [ -n "${line}" ]; do
    if [[ ${line} == '-- '*' --' ]]; then
      path="${line:3:${#line}-6}"
      # Strip the whitespace a marker may carry around the name, so that a name
      # can be padded to line the markers up.
      path="${path#"${path%%[![:space:]]*}"}"
      path="${path%"${path##*[![:space:]]}"}"

      if [ -z "${path}" ]; then
        flunk "Fixture marker line '${line}' does not name a file."
        return 1
      fi

      fixture_validate_path "${path}" || return 1

      case "${declared}" in
        *$'\n'"${path}"$'\n'*)
          flunk "Fixture path '${path}' is declared more than once."
          return 1
          ;;
      esac

      declared="${declared}${path}"$'\n'
      index=$((index + 1))
      paths+=("${path}")
      contents+=("")

      continue
    fi

    [ "${index}" -ge 0 ] || continue

    if [[ ${line} =~ ${escaped_marker} ]]; then
      line="${line:1}"
    fi

    contents[index]+="${line}"$'\n'
  done

  return 0
}

##
# Prints the regular files of a directory.
#
# Arguments:
#   1. dir: Directory to walk.
#
# Outputs:
#   STDOUT: One path per line, relative to the directory and sorted.
##
fixture_list_files() {
  local dir="${1}"

  local -a files=()
  local file

  while IFS= read -r -d '' file; do
    file="${file#./}"

    if [[ ${file} == *$'\n'* ]]; then
      flunk "Fixture file name '${file}' contains a newline, which a marker line cannot hold."
      return 1
    fi

    files+=("${file}")
  done < <(cd "${dir}" && find . -type f -print0)

  [ "${#files[@]}" -gt 0 ] || return 0

  printf '%s\n' "${files[@]}" | LC_ALL=C sort
}

##
# Validates that a path is one an archive may name.
#
# Arguments:
#   1. path: Path to validate, relative to the fixture directory.
##
fixture_validate_path() {
  local path="${1}"

  case "${path}" in
    /*)
      flunk "Fixture path '${path}' is absolute, but must be relative to the fixture directory."
      return 1
      ;;
    */)
      flunk "Fixture path '${path}' names a directory, but must name a file."
      return 1
      ;;
  esac

  case "/${path}/" in
    */../*)
      flunk "Fixture path '${path}' escapes the fixture directory."
      return 1
      ;;
    */./*)
      flunk "Fixture path '${path}' contains a '.' component, but must be a plain relative path."
      return 1
      ;;
  esac

  return 0
}
