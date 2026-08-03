#!/usr/bin/env bash
##
# @file
# Command mocking.
#
# A mock is a generated Bash script that sits first on PATH under the name of
# the command it stands in for. Every call it receives is recorded, appended to
# the shared call log, and answered from the responses the test configured.
#
# shellcheck disable=SC1090

##
## Sandbox.
##

##
# Sets up mock support.
#
# Call this from the test's 'setup' function.
#
# Globals:
#   BATS_HELPERS_MOCK_TMPDIR: Directory the mocks are stored in. Exported with
#     the resolved path.
#   PATH: Prepended with the mock directory for the duration of the test.
##
mock_setup() {
  BATS_HELPERS_MOCK_TMPDIR="$(mock_prepare_tmp)" || return 1
  export "BATS_HELPERS_MOCK_TMPDIR"

  # The mock directory goes first so that a mocked name is found ahead of the
  # real command. Bats restores PATH after the test, so this reaches no further.
  PATH="${BATS_HELPERS_MOCK_TMPDIR}:${PATH}"
}

##
# Resolves the directory that mocks are stored in.
#
# Globals:
#   BATS_HELPERS_MOCK_TMPDIR: Directory to use, when set.
#   BATS_TEST_TMPDIR: Per-test sandbox, used when no directory is set.
#
# Outputs:
#   STDOUT: Path to the directory.
#   STDERR: The reason the directory could not be resolved.
##
mock_resolve_tmp() {
  local dir

  if [ -n "${BATS_HELPERS_MOCK_TMPDIR-}" ]; then
    dir="${BATS_HELPERS_MOCK_TMPDIR}"
  elif [ -n "${BATS_MOCK_TMPDIR-}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'BATS_MOCK_TMPDIR' will be removed in the next version. Use 'BATS_HELPERS_MOCK_TMPDIR' instead." >&3
    dir="${BATS_MOCK_TMPDIR}"
  else
    dir="${BATS_TEST_TMPDIR-}"
  fi

  # The message is written directly rather than through 'flunk', because this is
  # the one failure that fires when the sandbox path is empty, which is exactly
  # what 'flunk' substitutes on.
  if [ -z "${dir}" ]; then
    echo "Mock directory cannot be resolved: 'BATS_TEST_TMPDIR' is not set. Set BATS_HELPERS_MOCK_TMPDIR to a writable directory." >&2
    return 1
  fi

  echo "${dir%/}"
}

##
# Prepares an empty directory for the mocks.
#
# Outputs:
#   STDOUT: Path to the directory.
##
mock_prepare_tmp() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  rm -rf "${dir}/bats-helpers-mock" >/dev/null || return 1
  mkdir -p "${dir}/bats-helpers-mock" || return 1

  echo "${dir}/bats-helpers-mock"
}

##
## Creation.
##

##
# Creates a mock that records how it was called.
#
# Globals:
#   BATS_HELPERS_MOCK_TMPDIR: Directory the mock is created in. Set to the
#     resolved path.
#   BATS_HELPERS_MOCK_STRICT: Whether the mock rejects the calls its
#     expectations do not cover. Defaults to '1'.
#
# Outputs:
#   STDOUT: Path to the mock.
##
mock_create() {
  BATS_HELPERS_MOCK_TMPDIR="$(mock_resolve_tmp)" || return 1

  # The notice is emitted here rather than from the mock, which runs as a
  # separate process with no file descriptor 3 to write to.
  if [ -z "${BATS_HELPERS_MOCK_USER-}" ] && [ -n "${_USER-}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: '_USER' will be removed in the next version. Use 'BATS_HELPERS_MOCK_USER' instead." >&3
  fi

  local index
  index="$(mock_next_index "${BATS_HELPERS_MOCK_TMPDIR}")"

  local mock="${BATS_HELPERS_MOCK_TMPDIR}/mock.$$.${index}"

  echo -n 0 >"${mock}.call_num"
  echo -n 0 >"${mock}.status"
  echo -n '' >"${mock}.output"
  echo -n '' >"${mock}.side_effect"
  echo -n "${mock##*/}" >"${mock}.name"
  echo -n "${BATS_HELPERS_MOCK_STRICT:-1}" >"${mock}.strict"

  # The modules are resolved to an absolute path because the code under test may
  # run the mock from any working directory.
  local src_dir
  src_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  mock_write "${mock}" "${src_dir}" "${BATS_HELPERS_MOCK_TMPDIR}/mock.log"
  chmod +x "${mock}"

  echo "${mock}"
}

##
# Creates a mock and puts it on PATH under a command name.
#
# Arguments:
#   1. mocked_command: Name of the command to stand in for.
#
# Outputs:
#   STDOUT: Path to the mock.
##
mock_command() {
  local mocked_command="${1?'Mocked command must be specified'}"

  local mock
  mock="$(mock_create)" || return 1

  local dir="${mock%/*}"
  ln -sf "${mock}" "${dir}/${mocked_command}"

  # The call log and the name-based assertions read the mocked command here.
  echo -n "${mocked_command}" >"${mock}.name"

  echo "${mock}"
}

##
# Reserves the next unused index for a mock.
#
# Arguments:
#   1. dir: Directory the mocks are stored in.
#
# Outputs:
#   STDOUT: The index.
##
mock_next_index() {
  local dir="${1}"
  local counter="${dir}/mock.$$.index"

  local index=0
  [ -e "${counter}" ] && index="$(cat "${counter}")"

  echo -n "$((index + 1))" >"${counter}"

  echo "${index}"
}

##
# Writes the script that stands in for the mocked command.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. src_dir: Directory holding the library's modules.
#   3. log: Path to the shared call log.
##
mock_write() {
  local mock="${1}"
  local src_dir="${2}"
  local log="${3}"

  # Every path is quoted for the shell rather than interpolated raw: the
  # directory holding it is consumer-supplied through BATS_HELPERS_MOCK_TMPDIR,
  # so a name carrying shell syntax would otherwise run when the mock does.
  local mock_quoted
  local src_dir_quoted
  local log_quoted
  printf -v mock_quoted '%q' "${mock}"
  printf -v src_dir_quoted '%q' "${src_dir}"
  printf -v log_quoted '%q' "${log}"

  cat <<EOF >"${mock}"
#!/usr/bin/env bash

set -e

mock=${mock_quoted}

source ${src_dir_quoted}/assert.string.bash
source ${src_dir_quoted}/mock.log.bash
source ${src_dir_quoted}/mock.match.bash
source ${src_dir_quoted}/mock.strict.bash

call_num="\$(( \$(cat "\${mock}.call_num") + 1 ))"
echo "\${call_num}" > "\${mock}.call_num"

echo "\${BATS_HELPERS_MOCK_USER:-\${_USER:-\$(id -un)}}" > "\${mock}.user.\${call_num}"

echo "\$@" > "\${mock}.args.\${call_num}"

for var in \$(compgen -e); do
  declare -p "\${var}"
done > "\${mock}.env.\${call_num}"

name="\$(cat "\${mock}.name")"
line="\$(mock_log_line "\${name}" "\$@")"
mock_log_append ${log_quoted} "\${line}"

if spec="\$(mock_match_index "\${mock}" "\$@")"; then
  mock_match_hit "\${mock}" "\${spec}"
elif ! mock_response_ordinal_exists "\${mock}" "\${call_num}"; then
  if mock_forward_enabled "\${mock}"; then
    mock_forward_exec "\${mock}" "\${name}" "\$@"
  fi

  if ! mock_strict_accepts "\${mock}"; then
    mock_strict_reject "\${mock}" "\${name}" "\${line}"
    exit 1
  fi
fi

cat "\$(mock_response_file "\${mock}" 'output' "\${call_num}" "\${spec}")"

source "\$(mock_response_file "\${mock}" 'side_effect' "\${call_num}" "\${spec}")"

exit "\$(cat "\$(mock_response_file "\${mock}" 'status' "\${call_num}" "\${spec}")")"
EOF
}

##
## Responses.
##

##
# Sets the exit status a mock responds with.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. status: Status.
#   3. n: Index of the call. Optional, defaults to every call.
##
mock_set_status() {
  local mock="${1?'Mock must be specified'}"
  local status="${2?'Status must be specified'}"
  local n="${3-}"

  mock_set_property "${mock}" 'status' "${status}" "${n}"
}

##
# Sets the output a mock responds with.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. output: Output or '-' for STDIN.
#   3. n: Index of the call. Optional, defaults to every call.
#
# Inputs:
#   STDIN: Output if 2 is '-'.
##
mock_set_output() {
  local mock="${1?'Mock must be specified'}"
  local output="${2?'Output must be specified'}"
  local n="${3-}"

  mock_set_property "${mock}" 'output' "${output}" "${n}"
}

##
# Sets the side effect a mock runs.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. side_effect: Bash code or '-' for STDIN.
#   3. n: Index of the call. Optional, defaults to every call.
#
# Inputs:
#   STDIN: Side effect if 2 is '-'.
##
mock_set_side_effect() {
  local mock="${1?'Mock must be specified'}"
  local side_effect="${2?'Side effect must be specified'}"
  local n="${3-}"

  mock_set_property "${mock}" 'side_effect' "${side_effect}" "${n}"
}

##
# Sets a specific response property of a mock.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. property_name: Property name.
#   3. property_value: Property value or '-' for STDIN.
#   4. n: Index of the call. Optional, defaults to every call.
#
# Inputs:
#   STDIN: Property value if 3 is '-'.
##
mock_set_property() {
  local mock="${1?'Mock must be specified'}"
  local property_name="${2?'Property name must be specified'}"
  local property_value="${3?'Property value must be specified'}"
  local n="${4-}"

  if [[ ${property_value} == '-' ]]; then
    property_value="$(cat -)"
  fi

  # The value is written with 'printf' because 'echo' would read a value of
  # '-n', '-e' or '-E' as one of its own flags and swallow it.
  if [ -z "${n}" ]; then
    printf '%s\n' "${property_value}" >"${mock}.${property_name}"

    # A response without a call index answers every call the expectations do
    # not cover.
    echo -n '' >"${mock}.default"

    return 0
  fi

  printf '%s\n' "${property_value}" >"${mock}.${property_name}.${n}"

  # A response carrying a call index is an expectation that the call arrives.
  mock_expect_ordinal "${mock}" "${n}"
}

##
## Calls.
##

##
# Prints the number of times a mock was called.
#
# Arguments:
#   1. mock: Path to the mock.
#
# Outputs:
#   STDOUT: Number of calls.
##
mock_get_call_num() {
  local mock="${1?'Mock must be specified'}"

  cat "${mock}.call_num"
}

##
# Prints the arguments a mock was called with.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. n: Index of the call. Optional, defaults to the last one.
#
# Outputs:
#   STDOUT: The arguments, separated by spaces.
##
mock_get_call_args() {
  local mock="${1?'Mock must be specified'}"
  local n
  n="$(mock_default_n "${mock}" "${2-}")" || return "$?"

  cat "${mock}.args.${n}"
}

##
# Prints the user a mock was called as.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. n: Index of the call. Optional, defaults to the last one.
#
# Outputs:
#   STDOUT: User name.
##
mock_get_call_user() {
  local mock="${1?'Mock must be specified'}"
  local n
  n="$(mock_default_n "${mock}" "${2-}")" || return "$?"

  cat "${mock}.user.${n}"
}

##
# Prints the value an environment variable held when a mock was called.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. var: Variable name.
#   3. n: Index of the call. Optional, defaults to the last one.
#
# Outputs:
#   STDOUT: Variable value.
##
mock_get_call_env() {
  local mock="${1?'Mock must be specified'}"
  local var="${2?'Variable name must be specified'}"
  local n
  n="$(mock_default_n "${mock}" "${3-}")" || return "$?"

  source "${mock}.env.${n}"

  echo "${!var}"
}

##
# Reports whether a mock was called with the expected arguments.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. expected_args: Expected arguments, separated by spaces, or '*' to accept
#      any arguments.
#   3. n: Index of the call. Optional, defaults to the last one.
#
# Returns:
#   0 when the arguments match, 1 when they do not. The mismatch is not
#   reported, so that a caller can word the failure in its own terms.
##
mock_assert_call_args() {
  local mock="${1?'Mock must be specified'}"
  local expected_args="${2?'Expected arguments must be specified'}"
  local n="${3-}"

  [[ ${expected_args} == "*" ]] && return 0

  local actual_args
  actual_args="$(mock_get_call_args "${mock}" "${n}")" || return 1

  [[ ${expected_args} == "${actual_args}" ]]
}

##
# Resolves a call index, defaulting to the last call.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. n: Index of the call. Optional.
#
# Outputs:
#   STDOUT: Call index.
##
mock_default_n() {
  local mock="${1?'Mock must be specified'}"

  local call_num
  call_num="$(cat "${mock}.call_num")"

  local n="${2:-${call_num}}"
  [ "${n}" -eq 0 ] && n=1

  if [ "${n}" -gt "${call_num}" ]; then
    flunk "Mock must be called at least ${n} time(s)."
    return 1
  fi

  echo "${n}"
}

##
## Registry.
##

##
# Prints the mocks created by the test.
#
# Outputs:
#   STDOUT: One mock path per line.
##
mock_paths() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local name_file
  for name_file in "${dir}"/*.name; do
    [ -e "${name_file}" ] || continue
    echo "${name_file%.name}"
  done

  return 0
}

##
# Prints the commands mocked by the test.
#
# Outputs:
#   STDOUT: One command name per line.
##
mock_names() {
  local paths
  paths="$(mock_paths)" || return 1

  [ -n "${paths}" ] || return 0

  local mock
  while IFS= read -r mock; do
    cat "${mock}.name"
    echo
  done <<<"${paths}"

  return 0
}

##
## Deprecated aliases, removed in the next version.
##

setup_mock() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'setup_mock' will be removed in the next version. Use 'mock_setup' instead." >&3
  mock_setup "$@"
}
