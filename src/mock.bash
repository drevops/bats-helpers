#!/usr/bin/env bash
##
# @file
# Command mocking.
#
# The function docblocks below are upstream text and are exempt from this
# repository's docblock style, so that the diff against upstream stays narrow.
# Local changes are marked with @note comments.
#
# @see https://github.com/grayhemp/bats-mock
#
# shellcheck disable=SC1090,SC2061

# Creates a mock program
# Globals:
#   BATS_MOCK_TMPDIR
#   BATS_TEST_TMPDIR
# Outputs:
#   STDOUT: Path to the mock
mock_create() {
  local index

  # @note: Modification to the original file: the directory is resolved by
  # mock_resolve_tmp(), which allows a custom location and defaults to the
  # per-test one. BATS_TMPDIR below was changed to BATS_MOCK_TMPDIR.
  BATS_MOCK_TMPDIR="$(mock_resolve_tmp)" || return 1

  index="$(find "${BATS_MOCK_TMPDIR}" -name bats-mock.$$.* | wc -l | tr -d ' ')"
  local mock
  mock="${BATS_MOCK_TMPDIR}/bats-mock.$$.${index}"
  echo -n 0 >"${mock}.call_num"
  echo -n 0 >"${mock}.status"
  echo -n '' >"${mock}.output"
  echo -n '' >"${mock}.side_effect"

  cat <<EOF >"${mock}"
#!/usr/bin/env bash

set -e

mock="${mock}"

call_num="\$(( \$(cat "\${mock}.call_num") + 1 ))"
echo "\${call_num}" > "\${mock}.call_num"

echo "\${_USER:-\$(id -un)}" > "\${mock}.user.\${call_num}"

echo "\$@" > "\${mock}.args.\${call_num}"

for var in \$(compgen -e); do
  declare -p "\${var}"
done > "\${mock}.env.\${call_num}"

if [[ -e "\${mock}.output.\${call_num}" ]]; then
  cat "\${mock}.output.\${call_num}"
else
  cat "\${mock}.output"
fi

if [[ -e "\${mock}.side_effect.\${call_num}" ]]; then
  source "\${mock}.side_effect.\${call_num}"
else
  source "\${mock}.side_effect"
fi

if [[ -e "\${mock}.status.\${call_num}" ]]; then
  exit "\$(cat "\${mock}.status.\${call_num}")"
else
  exit "\$(cat "\${mock}.status")"
fi
EOF
  chmod +x "${mock}"

  echo "${mock}"
}

# Sets the exit status of the mock
# Arguments:
#   1: Path to the mock
#   2: Status
#   3: Index of the call, optional
mock_set_status() {
  local mock="${1?'Mock must be specified'}"
  local status="${2?'Status must be specified'}"
  local n="${3-}"

  mock_set_property "${mock}" 'status' "${status}" "${n}"
}

# Sets the output of the mock
# Arguments:
#   1: Path to the mock
#   2: Output or - for STDIN
#   3: Index of the call, optional
mock_set_output() {
  local mock="${1?'Mock must be specified'}"
  local output="${2?'Output must be specified'}"
  local n="${3-}"

  mock_set_property "${mock}" 'output' "${output}" "${n}"
}

# Sets the side effect of the mock
# Arguments:
#   1: Path to the mock
#   2: Side effect or - for STDIN
#   3: Index of the call, optional
mock_set_side_effect() {
  local mock="${1?'Mock must be specified'}"
  local side_effect="${2?'Side effect must be specified'}"
  local n="${3-}"

  mock_set_property "${mock}" 'side_effect' "${side_effect}" "${n}"
}

# Returns the number of times the mock was called
# Arguments:
#   1: Path to the mock
# Outputs:
#   STDOUT: Number of calls
mock_get_call_num() {
  local mock="${1?'Mock must be specified'}"

  cat "${mock}.call_num"
}

# Returns the user the mock was called with
# Arguments:
#   1: Path to the mock
#   2: Index of the call, optional
# Outputs:
#   STDOUT: User name
mock_get_call_user() {
  local mock="${1?'Mock must be specified'}"
  local n
  n="$(mock_default_n "${mock}" "${2-}")" || return "$?"

  cat "${mock}.user.${n}"
}

# Returns the arguments line the mock was called with
# Arguments:
#   1: Path to the mock
#   2: Index of the call, optional
# Outputs:
#   STDOUT: Arguments line
mock_get_call_args() {
  local mock="${1?'Mock must be specified'}"
  local n
  n="$(mock_default_n "${mock}" "${2-}")" || return "$?"

  cat "${mock}.args.${n}"
}

# Checks if the mock was called with arguments matching the expected pattern
# Arguments:
#   1: Path to the mock
#   2: Expected arguments pattern (use "*" for wildcard matching)
#   3: Index of the call, optional
# Returns:
#   0: If arguments match (or wildcard), 1: If arguments don't match
mock_assert_call_args() {
  local mock="${1?'Mock must be specified'}"
  local expected_args="${2?'Expected arguments must be specified'}"
  local n="${3-}"

  # If expected args is "*", accept any arguments
  if [[ ${expected_args} == "*" ]]; then
    return 0
  fi

  local actual_args
  actual_args="$(mock_get_call_args "${mock}" "${n}")"

  if [[ ${expected_args} == "${actual_args}" ]]; then
    return 0
  else
    return 1
  fi
}

# Returns the value of the environment variable the mock was called with
# Arguments:
#   1: Path to the mock
#   2: Variable name
#   3: Index of the call, optional
# Outputs:
#   STDOUT: Variable value
mock_get_call_env() {
  local mock="${1?'Mock must be specified'}"
  local var="${2?'Variable name must be specified'}"
  local n
  # @note: Modification to the original file: the call index is optional, so it
  # is expanded with a default to keep it usable under 'nounset'.
  n="$(mock_default_n "${mock}" "${3-}")" || return "$?"

  source "${mock}.env.${n}"
  echo "${!var}"
}

# Sets a specific property of the mock
# Arguments:
#   1: Path to the mock
#   2: Property name
#   3: Property value or - for STDIN
#   4: Index of the call, optional
# Inputs:
#   STDIN: Property value if 2 is -
mock_set_property() {
  local mock="${1?'Mock must be specified'}"
  local property_name="${2?'Property name must be specified'}"
  local property_value="${3?'Property value must be specified'}"
  local n="${4-}"

  if [[ ${property_value} == '-' ]]; then
    property_value="$(cat -)"
  fi

  if [[ -n ${n} ]]; then
    echo -e "${property_value}" >"${mock}.${property_name}.${n}"
  else
    echo -e "${property_value}" >"${mock}.${property_name}"
  fi
}

# Defaults call index to the last one if not specified explicitly
# Arguments:
#   1: Path to the mock
#   2: Index of the call, optional
# Returns:
#   1: If mock is not called enough times
# Outputs:
#   STDOUT: Call index
#   STDERR: Corresponding error message
mock_default_n() {
  local mock="${1?'Mock must be specified'}"
  local call_num
  call_num="$(cat "${mock}.call_num")"
  local n="${2:-${call_num}}"

  if [[ ${n} -eq 0 ]]; then
    n=1
  fi

  # @note: Modification to the original file: 'return' instead of 'exit' keeps
  # the failure recoverable, as this function runs in the test's own shell.
  if [[ ${n} -gt ${call_num} ]]; then
    echo "$(basename "$0"): Mock must be called at least ${n} time(s)" >&2
    return 1
  fi

  echo "${n}"
}

# Setup mock support.
# Call this function from your test's setup() method.
mock_setup() {
  # Command and functions mocking support.
  # @see https://github.com/grayhemp/bats-mock
  #
  # Prepare directory with mock binaries, get it's path, and export it so that
  # bats-mock could use it internally.
  BATS_MOCK_TMPDIR="$(mock_prepare_tmp)" || return 1
  export "BATS_MOCK_TMPDIR"
  # Set the path to temp mocked binaries directory as the first location in
  # PATH to lookup in mock directories first. This change lives only for the
  # duration of the test and will be reset after. It does not modify the PATH
  # outside of the running test.
  PATH="${BATS_MOCK_TMPDIR}:${PATH}"
}

# Resolves the directory that mocks are stored in.
# Globals:
#   BATS_MOCK_TMPDIR
#   BATS_TEST_TMPDIR
# Returns:
#   1: If neither of the globals is set
# Outputs:
#   STDOUT: Path to the directory
#   STDERR: Corresponding error message
mock_resolve_tmp() {
  local dir="${BATS_MOCK_TMPDIR:-${BATS_TEST_TMPDIR-}}"

  if [ -z "${dir}" ]; then
    echo "Unable to resolve the mock directory: BATS_TEST_TMPDIR is not set. Set BATS_MOCK_TMPDIR to a writable directory" >&2
    return 1
  fi

  echo "${dir%/}"
}

# Prepare temporary mock directory.
mock_prepare_tmp() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  rm -rf "${dir}/bats-mock-tmp" >/dev/null || return 1
  mkdir -p "${dir}/bats-mock-tmp" || return 1

  echo "${dir}/bats-mock-tmp"
}

# Mock provided command.
# Arguments:
#  1. Mocked command name,
# Outputs:
#   STDOUT: path to created mock file.
mock_command() {
  local mocked_command="${1?'Mocked command must be specified'}"
  local mock
  mock="$(mock_create)"
  local mock_path="${mock%/*}"
  local mock_file="${mock##*/}"
  ln -sf "${mock_path}/${mock_file}" "${mock_path}/${mocked_command}"
  echo "${mock}"
}

##
## Deprecated aliases, removed in the next version.
##

setup_mock() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'setup_mock' will be removed in the next version. Use 'mock_setup' instead." >&3
  mock_setup "$@"
}
