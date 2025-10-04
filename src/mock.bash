# A Bats helper library providing mocking functionality.
# @see https://github.com/grayhemp/bats-mock
#
# Allow to provide custom temp directory for mocks.
export BATS_MOCK_TMPDIR="${BATS_MOCK_TMPDIR:-$BATS_TMPDIR}"

# Setup mock support. Call this function from your test's setup() method.
# Globals:
#   BATS_MOCK_TMPDIR
setup_mock() {
  # Prepare directory with mock binaries, get it's path, and export it so that
  # bats-mock could use it internally.
  mkdir -p "${BATS_MOCK_TMPDIR}"

  # Set the path to mocked binaries directory as the first location in PATH to
  # lookup in mock directories first. This change lives only for the duration
  # of the test and will be reset after. It does not modify the PATH outside of
  # the running test.
  PATH="$(path_prefix "$(__get_mock_bin_dir)")"
}

# Performs cleanup of mock objects
# Globals:
#   BATS_MOCK_TMPDIR
teardown_mock() {
  rm -rf "$(__get_mock_filename)"*
}

# Creates a mock program
# Globals:
#   BATS_MOCK_TMPDIR
# Arguments:
#   1: Command to mock, optional
# Returns:
#   1: If the mock command already exists
#   1: If the command provided with an absolute path already exists
# Outputs:
#   STDOUT: Path to the mock or the mocked command
#   STDERR: Corresponding error message
mock_create() {
  local cmd="${1-}"
  local index
  local mock

  mock=$(__get_mock_filename)
  # A test may create more than one mock, so we need to ensure unique names
  index="$(find "$(dirname "${mock}")" -regex "${mock}.[0-9]*" | wc -l | tr -d ' ')"
  mock="${mock}.${index}"

  # If command is provided, create command by linking it to the mock
  if [[ -n ${cmd} ]]; then
    # Exit if we can't create the symbolic link
    cmd=$(mock_set_command "${mock}" "${cmd}") || exit $?
  fi

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

  if [[ -n ${cmd} ]]; then
    echo "${cmd}"
  else
    echo "${mock}"
  fi
}

# Returns the absolute path to the mock, unique per test process
# Globals:
#   BATS_MOCK_TMPDIR
__get_mock_filename() {
  # Use the process ID to assure each test gets its own name space. Otherwise
  # we may get collisions when tests run in parallel.
  echo "${BATS_MOCK_TMPDIR}/bats-mock.$$"
}

# Returns path to the directory for mocked commands
__get_mock_bin_dir() {
  echo "$(__get_mock_filename).bin"
}

# Creates a symbolic link with given name to a mock program
# Globals:
#   BATS_MOCK_TMPDIR
# Arguments:
#   1: Path to the mock
#   2: Command name
# Outputs:
#   STDOUT: Path to the mocked command
mock_set_command() {
  local mock="${1?'Mocked command must be specified'}"
  local cmd="${2?'Command must be specified'}"

  # Directory with mocked commands
  local mock_bin_dir

  # Is the command provided as absolute path?
  if [[ ${cmd} == /* ]]; then
    # Use parameter expansion to get the folder portion of the command's path
    mock_bin_dir="${cmd%/*}"
  else
    # Otherwise use the default directory
    mock_bin_dir="$(__get_mock_bin_dir)"
    cmd="${mock_bin_dir}/${cmd}"
  fi

  # Create command stub by linking it to the mock
  mkdir -p "${mock_bin_dir}"
  ln -s "${mock}" "${cmd}" && echo "${cmd}"
}

# Mock provided command.
# Arguments:
#  1. Mocked command name,
# Outputs:
#   STDOUT: path to created mock file.
mock_command() {
  mocked_command="${1?'Mocked command must be specified'}"
  mock="$(mock_create "${mocked_command}")"
  echo "$mock"
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

  # Resolve symbolic links to their real path
  if [[ -L "$mock" ]]; then
    mock="$(readlink -f "$mock")"
  fi

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
  # Resolve symbolic links to their real path
  if [[ -L "$mock" ]]; then
    mock="$(readlink -f "$mock")"
  fi

  local n
  n="$(mock_default_n "${mock}" "${2-}")" || exit "$?"

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

  # Resolve symbolic links to their real path
  if [[ -L "$mock" ]]; then
    mock="$(readlink -f "$mock")"
  fi

  local n
  n="$(mock_default_n "${mock}" "${2-}")" || exit "$?"

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
  local n="${3-}"
  n="$(mock_default_n "${mock}" "${3}")" || exit "$?"

  # shellcheck source=/dev/null
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

  # Resolve symbolic links to their real path
  if [[ -L "$mock" ]]; then
    mock="$(readlink -f "$mock")"
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

  if [[ ${n} -gt ${call_num} ]]; then
    echo "$(basename "$0"): Mock must be called at least ${n} time(s)" >&2
    exit 1
  fi

  echo "${n}"
}

# Returns a path prefixed with the mock's directory
# Arguments:
#   1: Path to the mock which may be a file, directory or link
#   2: Path to be prefixed by the path from the 1st argument. Defaults to $PATH if not provided.
# Outputs:
#   STDOUT: the path prefixed with the mock's directory
path_prefix() {
  local mock="${1?'Mock must be specified'}"
  local path=${2:-${PATH}}
  local mock_path="${mock}"

  if [[ -f ${mock} ]]; then
    # Parameter expansion to get the folder portion of the mock's path
    local mock_path="${mock%/*}"
  fi

  # Putting the directory with the mocked commands at the beginning of the PATH
  # so it gets picked up first
  if [[ :${path}: == *:${mock_path}:* ]]; then
    echo "${path}"
  else
    echo "${mock_path}:${path}"
  fi
}

# Returns $PATH without a provided path
# Arguments:
#   1: Path to be removed
#   2: Path from which the 1st argument is removed. Defaults to $PATH if not provided.
# Outputs:
#   STDOUT: a path without the path provided in ${1}
path_rm() {
  local path_to_remove=${1?'Path or command to remove must be specified'}
  local path=${2:-${PATH}}
  if [[ -f ${path_to_remove} ]]; then
    # Parameter expansion to get the folder portion of the temp mock's path
    path_to_remove=${path_to_remove%/*}
  fi
  path=":$path:"
  path=${path//":"/"::"}
  path=${path//":${path_to_remove}:"/}
  path=${path//"::"/":"}
  path=${path#:}
  path=${path%:}
  echo "${path}"
}
