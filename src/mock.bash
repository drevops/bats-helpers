#!/usr/bin/env bash
##
# @file
# Command mocking.
#
# A mock is a generated Bash script that sits first on PATH under the name of
# the command it stands in for. Every call it receives is recorded, appended to
# the shared call log, and answered from the responses the test configured.
#
# That generated script runs as its own process and sources this file, where the
# assertion helpers are not loaded. Every function it reaches at that point says
# so in its docblock and must never call 'flunk'.
#
# shellcheck disable=SC1090

##
## Mock directory.
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

  mock_path_record
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
# Records the PATH that the mocks are found on.
#
# Globals:
#   PATH: Written to the record so that a later change to it is detectable.
##
mock_path_record() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  printf '%s\n' "${PATH}" >"${dir}/.path"
}

##
# Warns when PATH changed after the mocks were put on it.
#
# Code under test that rewrites PATH disables the mocking silently: the test
# then passes while exercising the real system, which is the failure this
# reports.
#
# Outputs:
#   File descriptor 3: The warning, when PATH no longer matches the record.
#
# Returns:
#   0 always. The change is reported as a warning rather than by the exit
#   status, so that a caller can report it without failing on it.
##
mock_path_check() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local record="${dir}/.path"
  [ -e "${record}" ] || return 0

  local recorded
  recorded="$(cat "${record}")"

  [ "${recorded}" = "${PATH}" ] && return 0

  if mock_path_contains "${dir}"; then
    echo "Warning: 'PATH' changed after 'mock_setup'. The mocks are still found, but a command the test did not mock may resolve differently." >&3
    return 0
  fi

  echo "Warning: 'PATH' changed after 'mock_setup' and no longer holds the mock directory '${dir}'. Mocked commands are not found and the real commands run instead." >&3
}

##
# Reports whether a directory is on PATH.
#
# Arguments:
#   1. dir: Directory to look for.
##
mock_path_contains() {
  local dir="${1}"

  local -a entries=()
  IFS=':' read -ra entries <<<"${PATH}"

  local entry
  for entry in "${entries[@]}"; do
    [ "${entry}" = "${dir}" ] && return 0
  done

  return 1
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
source ${src_dir_quoted}/mock.bash

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
## Argument specifications.
##

##
# Adds an argument specification to a mock.
#
# A specification selects the response for the calls its matchers accept. The
# first specification whose every matcher accepts a call wins, in the order the
# specifications were added, and a call that no specification accepts falls
# through to the per-call and default responses.
#
# Arguments:
#   1. mock: Path to the mock.
#
# Outputs:
#   STDOUT: Path prefix identifying the specification, to pass to the other
#           'mock_spec_' functions.
##
mock_spec_add() {
  local mock="${1?'Mock must be specified'}"

  if [ ! -e "${mock}" ]; then
    flunk "Mock '${mock}' does not exist. Create it with 'mock_command' first."
    return 1
  fi

  local spec_num=0
  [ -e "${mock}.spec_num" ] && spec_num="$(cat "${mock}.spec_num")"

  spec_num=$((spec_num + 1))
  echo -n "${spec_num}" >"${mock}.spec_num"

  local spec="${mock}.spec.${spec_num}"
  echo -n 0 >"${spec}.arg_num"
  echo -n 0 >"${spec}.hits"

  echo "${spec}"
}

##
# Constrains one argument position of a specification.
#
# Arguments:
#   1. spec: Specification returned by 'mock_spec_add'.
#   2. position: One-based argument position, or '*' to require that some
#      argument satisfies the matcher.
#   3. matcher: One of 'equals', 'starts_with', 'ends_with', 'contains',
#      'matches' or 'present', each of which may carry a 'not_' prefix. At '*'
#      a prefixed matcher requires that no argument satisfies it.
#   4. value: Value to match against. Required by every matcher except
#      'present' and 'not_present', which take none.
##
mock_spec_arg() {
  local spec="${1?'Specification must be specified'}"
  local position="${2?'Position must be specified'}"
  local matcher="${3?'Matcher must be specified'}"
  local value="${4-}"

  if [ ! -e "${spec}.arg_num" ]; then
    flunk "Specification '${spec}' does not exist. Create it with 'mock_spec_add' first."
    return 1
  fi

  if [ "${position}" != "*" ] && ! [[ ${position} =~ ^[1-9][0-9]*$ ]]; then
    flunk "Position '${position}' is not a positive integer or '*'."
    return 1
  fi

  case "${matcher}" in
    equals | not_equals | starts_with | not_starts_with | ends_with | not_ends_with | contains | not_contains | matches | not_matches | present | not_present) ;;
    *)
      flunk "Matcher '${matcher}' is not known. Use 'equals', 'starts_with', 'ends_with', 'contains', 'matches' or 'present', optionally prefixed with 'not_'."
      return 1
      ;;
  esac

  if [ "${matcher}" = "present" ] || [ "${matcher}" = "not_present" ]; then
    if [ "$#" -gt 3 ]; then
      flunk "Matcher '${matcher}' takes no value."
      return 1
    fi
  elif [ "$#" -lt 4 ]; then
    flunk "Matcher '${matcher}' requires a value."
    return 1
  fi

  if [ "${matcher}" = "matches" ] || [ "${matcher}" = "not_matches" ]; then
    local match_status=0
    string_match "" "${value}" "regex" 1 "anywhere" || match_status=$?

    if [ "${match_status}" -eq 2 ]; then
      flunk "Invalid regular expression '${value}'."
      return 1
    fi
  fi

  local arg_num
  arg_num="$(cat "${spec}.arg_num")"

  # A numeric position constrained twice would make the specification depend on
  # which of the two constraints was consulted first.
  if [ "${position}" != "*" ]; then
    local i
    for ((i = 1; i <= arg_num; i++)); do
      if [ "$(cat "${spec}.arg.${i}.position")" = "${position}" ]; then
        flunk "Position '${position}' is already constrained by this specification."
        return 1
      fi
    done
  fi

  arg_num=$((arg_num + 1))
  echo -n "${arg_num}" >"${spec}.arg_num"

  echo -n "${position}" >"${spec}.arg.${arg_num}.position"
  echo -n "${matcher}" >"${spec}.arg.${arg_num}.matcher"
  printf '%s' "${value}" >"${spec}.arg.${arg_num}.value"
}

##
# Pins the number of arguments a specification accepts.
#
# Arguments:
#   1. spec: Specification returned by 'mock_spec_add'.
#   2. count: Number of arguments.
##
mock_spec_count() {
  local spec="${1?'Specification must be specified'}"
  local count="${2?'Count must be specified'}"

  if [ ! -e "${spec}.arg_num" ]; then
    flunk "Specification '${spec}' does not exist. Create it with 'mock_spec_add' first."
    return 1
  fi

  if ! [[ ${count} =~ ^[0-9]+$ ]]; then
    flunk "Count '${count}' is not a non-negative integer."
    return 1
  fi

  echo -n "${count}" >"${spec}.argc"
}

##
# Sets the exit status a specification responds with.
#
# Arguments:
#   1. spec: Specification returned by 'mock_spec_add'.
#   2. status: Status.
##
mock_spec_set_status() {
  local spec="${1?'Specification must be specified'}"
  local status="${2?'Status must be specified'}"

  mock_spec_set_property "${spec}" 'status' "${status}"
}

##
# Sets the output a specification responds with.
#
# Arguments:
#   1. spec: Specification returned by 'mock_spec_add'.
#   2. output: Output or '-' for STDIN.
#
# Inputs:
#   STDIN: Output if 2 is '-'.
##
mock_spec_set_output() {
  local spec="${1?'Specification must be specified'}"
  local output="${2?'Output must be specified'}"

  mock_spec_set_property "${spec}" 'output' "${output}"
}

##
# Sets the side effect a specification runs.
#
# Arguments:
#   1. spec: Specification returned by 'mock_spec_add'.
#   2. side_effect: Side effect or '-' for STDIN.
#
# Inputs:
#   STDIN: Side effect if 2 is '-'.
##
mock_spec_set_side_effect() {
  local spec="${1?'Specification must be specified'}"
  local side_effect="${2?'Side effect must be specified'}"

  mock_spec_set_property "${spec}" 'side_effect' "${side_effect}"
}

##
# Sets a specific property of a specification.
#
# Arguments:
#   1. spec: Specification returned by 'mock_spec_add'.
#   2. property_name: Property name.
#   3. property_value: Property value or '-' for STDIN.
#
# Inputs:
#   STDIN: Property value if 3 is '-'.
##
mock_spec_set_property() {
  local spec="${1}"
  local property_name="${2}"
  local property_value="${3}"

  if [ ! -e "${spec}.arg_num" ]; then
    flunk "Specification '${spec}' does not exist. Create it with 'mock_spec_add' first."
    return 1
  fi

  if [[ ${property_value} == '-' ]]; then
    property_value="$(cat -)"
  fi

  # The value is written with 'printf' because 'echo' would read a value of
  # '-n', '-e' or '-E' as one of its own flags and swallow it.
  printf '%s\n' "${property_value}" >"${spec}.${property_name}"
}

##
# Runs the real command for calls that no specification accepts.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. enabled: '1' to forward, '0' to stop forwarding. Optional, defaults
#      to '1'.
##
mock_set_forward() {
  local mock="${1?'Mock must be specified'}"
  local enabled="${2:-1}"

  if [ ! -e "${mock}" ]; then
    flunk "Mock '${mock}' does not exist. Create it with 'mock_command' first."
    return 1
  fi

  if [ "${enabled}" != "0" ] && [ "${enabled}" != "1" ]; then
    flunk "Forwarding must be '0' or '1', got '${enabled}'."
    return 1
  fi

  if [ "${enabled}" = "0" ]; then
    rm -f "${mock}.forward"
    return 0
  fi

  echo -n 1 >"${mock}.forward"
}

##
## Matching.
##

##
# Reports which specification accepts a call.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#   2+. Arguments the command was called with.
#
# Outputs:
#   STDOUT: Index of the first accepting specification.
#
# Returns:
#   0 when a specification accepts the call, 1 when none does.
##
mock_match_index() {
  local mock="${1}"
  shift

  [ -e "${mock}.spec_num" ] || return 1

  local spec_num
  spec_num="$(cat "${mock}.spec_num")"

  local i
  for ((i = 1; i <= spec_num; i++)); do
    if mock_spec_matches "${mock}.spec.${i}" "$@"; then
      echo "${i}"
      return 0
    fi
  done

  return 1
}

##
# Records that a specification accepted a call.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. index: Index of the specification.
##
mock_match_hit() {
  local mock="${1}"
  local index="${2}"
  local spec="${mock}.spec.${index}"

  local hits
  hits="$(cat "${spec}.hits")"

  echo -n "$((hits + 1))" >"${spec}.hits"
}

##
# Reports whether a specification accepts a call.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. spec: Path prefix of the specification.
#   2+. Arguments the command was called with.
#
# Returns:
#   0 when every matcher accepts the call, 1 when one of them does not.
##
mock_spec_matches() {
  local spec="${1}"
  shift

  if [ -e "${spec}.argc" ]; then
    [ "$#" -eq "$(cat "${spec}.argc")" ] || return 1
  fi

  local arg_num
  arg_num="$(cat "${spec}.arg_num")"

  local i
  local position
  local matcher
  local value
  local negate

  for ((i = 1; i <= arg_num; i++)); do
    position="$(cat "${spec}.arg.${i}.position")"
    matcher="$(cat "${spec}.arg.${i}.matcher")"
    value="$(cat "${spec}.arg.${i}.value")"

    negate=0
    if [ "${matcher#not_}" != "${matcher}" ]; then
      negate=1
      matcher="${matcher#not_}"
    fi

    if [ "${position}" = "*" ]; then
      mock_match_any "${matcher}" "${value}" "${negate}" "$@" || return 1
    else
      mock_match_at "${position}" "${matcher}" "${value}" "${negate}" "$@" || return 1
    fi
  done

  return 0
}

##
# Reports whether the argument at a position satisfies a matcher.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. position: One-based argument position.
#   2. matcher: Matcher without its 'not_' prefix.
#   3. value: Value to match against.
#   4. negate: '1' to require that the argument does not satisfy the matcher.
#   5+. Arguments the command was called with.
##
mock_match_at() {
  local position="${1}"
  local matcher="${2}"
  local value="${3}"
  local negate="${4}"
  shift 4

  local matched=0

  if [ "${matcher}" = "present" ]; then
    [ "${position}" -le "$#" ] && matched=1
  elif [ "${position}" -le "$#" ]; then
    mock_match_value "${!position}" "${matcher}" "${value}" && matched=1
  fi

  [ "${negate}" = "1" ] && matched=$((1 - matched))

  [ "${matched}" = "1" ]
}

##
# Reports whether some argument satisfies a matcher.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. matcher: Matcher without its 'not_' prefix.
#   2. value: Value to match against.
#   3. negate: '1' to require that no argument satisfies the matcher.
#   4+. Arguments the command was called with.
##
mock_match_any() {
  local matcher="${1}"
  local value="${2}"
  local negate="${3}"
  shift 3

  local matched=0

  if [ "${matcher}" = "present" ]; then
    [ "$#" -gt 0 ] && matched=1
  else
    local argument
    for argument in "$@"; do
      if mock_match_value "${argument}" "${matcher}" "${value}"; then
        matched=1
        break
      fi
    done
  fi

  [ "${negate}" = "1" ] && matched=$((1 - matched))

  [ "${matched}" = "1" ]
}

##
# Reports whether one value satisfies a matcher.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. value: Value to test.
#   2. matcher: Matcher without its 'not_' prefix.
#   3. needle: Value to match against.
#
# Returns:
#   0 when the value satisfies the matcher, 1 when it does not or the matcher
#   is not known.
##
mock_match_value() {
  local value="${1}"
  local matcher="${2}"
  local needle="${3}"

  case "${matcher}" in
    equals)
      [ "${value}" = "${needle}" ]
      ;;
    starts_with)
      string_match "${value}" "${needle}" "literal" 1 "start"
      ;;
    ends_with)
      string_match "${value}" "${needle}" "literal" 1 "end"
      ;;
    contains)
      string_match "${value}" "${needle}" "literal" 1 "anywhere"
      ;;
    matches)
      string_match "${value}" "${needle}" "regex" 1 "anywhere"
      ;;
    *)
      return 1
      ;;
  esac
}

##
# Writes what a specification requires of a call.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. spec: Path prefix of the specification.
#
# Outputs:
#   STDOUT: The requirements, comma-separated.
##
mock_spec_describe() {
  local spec="${1}"
  local description=""

  local arg_num
  arg_num="$(cat "${spec}.arg_num")"

  local i
  local position
  local matcher
  local value

  for ((i = 1; i <= arg_num; i++)); do
    position="$(cat "${spec}.arg.${i}.position")"
    matcher="$(cat "${spec}.arg.${i}.matcher")"
    value="$(cat "${spec}.arg.${i}.value")"

    [ -n "${description}" ] && description="${description}, "

    if [ "${position}" = "*" ]; then
      description="${description}some argument ${matcher}"
    else
      description="${description}argument ${position} ${matcher}"
    fi

    case "${matcher}" in
      present | not_present) ;;
      *)
        description="${description} '${value}'"
        ;;
    esac
  done

  if [ -e "${spec}.argc" ]; then
    [ -n "${description}" ] && description="${description}, "
    description="${description}$(cat "${spec}.argc") argument(s)"
  fi

  [ -z "${description}" ] && description="any call"

  echo "${description}"
}

##
# Writes what each specification of a mock requires of a call.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#
# Outputs:
#   STDOUT: One indented line per specification, and nothing when the mock has
#           none.
##
mock_spec_describe_all() {
  local mock="${1}"

  [ -e "${mock}.spec_num" ] || return 0

  local spec_num
  spec_num="$(cat "${mock}.spec_num")"

  local i
  for ((i = 1; i <= spec_num; i++)); do
    echo "  specification ${i}: $(mock_spec_describe "${mock}.spec.${i}")"
  done

  return 0
}

##
# Resolves the file holding a response property for a call.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. property: Property name.
#   3. call_num: Index of the call.
#   4. spec: Index of the accepting specification. Optional.
#
# Outputs:
#   STDOUT: Path to the specification's file, else the call's own file, else
#           the mock's default file.
##
mock_response_file() {
  local mock="${1}"
  local property="${2}"
  local call_num="${3}"
  local spec="${4-}"

  if [ -n "${spec}" ] && [ -e "${mock}.spec.${spec}.${property}" ]; then
    echo "${mock}.spec.${spec}.${property}"
    return 0
  fi

  if [ -e "${mock}.${property}.${call_num}" ]; then
    echo "${mock}.${property}.${call_num}"
    return 0
  fi

  echo "${mock}.${property}"
}

##
# Reports whether a call has a response of its own.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. call_num: Index of the call.
#
# Returns:
#   0 when any response property is configured for the call, 1 when none is.
##
mock_response_ordinal_exists() {
  local mock="${1}"
  local call_num="${2}"

  [ -e "${mock}.status.${call_num}" ] && return 0
  [ -e "${mock}.output.${call_num}" ] && return 0
  [ -e "${mock}.side_effect.${call_num}" ] && return 0

  return 1
}

##
# Reports whether a mock forwards unaccepted calls to the real command.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_forward_enabled() {
  local mock="${1}"

  [ -e "${mock}.forward" ]
}

##
# Replaces the mock process with the real command.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. name: Command name.
#   3+. Arguments the command was called with.
#
# Outputs:
#   STDERR: A diagnostic when the real command is not on PATH.
#
# Returns:
#   Never returns to the caller. The process is replaced by the real command,
#   or exits 127 when the real command is not on PATH.
##
mock_forward_exec() {
  local mock="${1}"
  local name="${2}"
  shift 2

  local forward_path
  forward_path="$(mock_forward_path "${mock%/*}")"

  local real
  real="$(PATH="${forward_path}" command -v "${name}")" || real=""

  if [ -z "${real}" ]; then
    echo "Command '${name}' is not available to forward to" >&2
    exit 127
  fi

  # A builtin resolves to a bare name, which 'exec' looks up on PATH, where the
  # mock directory would otherwise still come first.
  PATH="${forward_path}" exec "${real}" "$@"
}

##
# Writes PATH without the directory the mocks are stored in.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. dir: Directory to remove.
#   2. path: Value to remove it from. Optional, defaults to the current PATH.
#
# Outputs:
#   STDOUT: The remaining PATH entries.
##
mock_forward_path() {
  local dir="${1}"
  local path="${2-${PATH}}"
  local -a entries=()
  local -a kept=()

  IFS=':' read -ra entries <<<"${path}"

  local entry
  for entry in "${entries[@]}"; do
    [ "${entry}" = "${dir}" ] && continue
    kept+=("${entry}")
  done

  local joined
  printf -v joined '%s:' "${kept[@]}"

  echo "${joined%:}"
}

##
## Strictness.
##
## An expectation is a response configured for one call index or an argument
## specification. A mock with no expectations records calls without constraining
## them; a mock with at least one expectation rejects the calls that none of
## them covers, unless a response set without a call index has declared a
## catch-all.
##

##
# Rejects the calls a mock's expectations do not cover.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. enabled: '1' to reject, '0' to answer every call. Optional, defaults
#      to '1'.
##
mock_set_strict() {
  local mock="${1?'Mock must be specified'}"
  local enabled="${2:-1}"

  if [ ! -e "${mock}" ]; then
    flunk "Mock '${mock}' does not exist. Create it with 'mock_command' first."
    return 1
  fi

  if [ "${enabled}" != "0" ] && [ "${enabled}" != "1" ]; then
    flunk "Strictness must be '0' or '1', got '${enabled}'."
    return 1
  fi

  echo -n "${enabled}" >"${mock}.strict"
}

##
# Reports whether a mock rejects the calls its expectations do not cover.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_strict_enabled() {
  local mock="${1}"

  [ -e "${mock}.strict" ] || return 1

  [ "$(cat "${mock}.strict")" = "1" ]
}

##
# Records that a response was configured for a call index.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. n: Index of the call.
##
mock_expect_ordinal() {
  local mock="${1}"
  local n="${2}"
  local file="${mock}.expect_ordinal"

  local recorded
  if [ -e "${file}" ]; then
    while IFS= read -r recorded; do
      [ "${recorded}" = "${n}" ] && return 0
    done <"${file}"
  fi

  printf '%s\n' "${n}" >>"${file}"
}

##
# Reports whether a mock has any expectation.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_has_expectations() {
  local mock="${1}"

  [ -e "${mock}.expect_ordinal" ] && return 0
  [ -e "${mock}.spec_num" ] && return 0

  return 1
}

##
# Reports whether a mock answers a call no expectation covers.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
##
mock_strict_accepts() {
  local mock="${1}"

  mock_strict_enabled "${mock}" || return 0
  [ -e "${mock}.default" ] && return 0
  mock_has_expectations "${mock}" || return 0

  return 1
}

##
# Records a call that no expectation covers.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. mock: Path to the mock.
#   2. name: Command name.
#   3. line: The call, serialised by 'mock_log_line'.
#
# Outputs:
#   STDERR: A diagnostic naming the call and every specification that turned
#           it down.
##
mock_strict_reject() {
  local mock="${1}"
  local name="${2}"
  local line="${3}"

  echo "Mock '${name}' received a call that no expectation covers: ${line}" >&2
  mock_spec_describe_all "${mock}" >&2

  printf '%s\n' "${line}" >>"${mock}.unexpected"
}

##
## Sandbox mode.
##
## Off until a test enables it. Once enabled, PATH holds the mock directory and
## a directory of the commands the test allowed, so a command the test neither
## mocked nor allowed does not run.
##
## This is not a security boundary. An absolute path reaches the real command
## whatever PATH holds, and the commands the library and the BATS harness run
## stay available so that both keep working inside the mode.
##

##
# Enables the sandbox mode for the current test.
#
# Arguments:
#   1+. command: Commands that must run for real, as 'mock_sandbox_allow' takes
#       them. Optional.
#
# Globals:
#   PATH: Replaced with the mock directory and the sandbox directory.
#   BATS_HELPERS_MOCK_SANDBOX_REPORT: Exported with the path to the report, so
#     that the denial reaches it from whichever process hit the failed lookup.
##
mock_sandbox_enable() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local sandbox="${dir}/.sandbox"

  if ! mkdir -p "${sandbox}/bin"; then
    flunk "Sandbox directory '${sandbox}/bin' cannot be created."
    return 1
  fi

  # The value is saved once, so that enabling an already-enabled sandbox does
  # not record the sandbox over the PATH it has to be restored to.
  [ -e "${sandbox}/path" ] || printf '%s\n' "${PATH}" >"${sandbox}/path"

  mock_sandbox_link_base "${sandbox}/bin" || return 1

  if [ "$#" -gt 0 ]; then
    mock_sandbox_allow "$@" || return 1
  fi

  BATS_HELPERS_MOCK_SANDBOX_REPORT="${sandbox}/report"
  export BATS_HELPERS_MOCK_SANDBOX_REPORT

  # Bash consults this on every failed lookup. It is defined here rather than at
  # file scope so that loading the library leaves the shell's lookups alone, and
  # exported so that a Bash script under test reports the same way the test
  # shell does.
  command_not_found_handle() { mock_sandbox_deny "$@"; }
  export -f mock_sandbox_deny
  export -f command_not_found_handle

  PATH="${dir}:${sandbox}/bin"

  mock_path_record
}

##
# Allows commands to run for real inside the sandbox.
#
# Each call reaching an allowed command is recorded as an escape, so that
# 'mock_sandbox_report' names what left the mock boundary.
#
# Arguments:
#   1+. command: Command names.
##
mock_sandbox_allow() {
  if [ "$#" -eq 0 ]; then
    flunk "At least one command name is required."
    return 1
  fi

  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local sandbox="${dir}/.sandbox"

  if ! mkdir -p "${sandbox}/bin"; then
    flunk "Sandbox directory '${sandbox}/bin' cannot be created."
    return 1
  fi

  local real_path
  real_path="$(mock_sandbox_real_path)" || return 1

  local name
  local real
  for name in "$@"; do
    # 'type -P' searches PATH even when a builtin or a function carries the same
    # name, which is what the shim needs: a file to hand the call to.
    real="$(PATH="${real_path}" type -P "${name}")" || real=""

    case "${real}" in
      /*) ;;
      *)
        flunk "Command '${name}' cannot be allowed: it is not on 'PATH'."
        return 1
        ;;
    esac

    mock_sandbox_write_shim "${sandbox}/bin/${name}" "${name}" "${real}" "${sandbox}/report"
    chmod +x "${sandbox}/bin/${name}"
  done
}

##
# Disables the sandbox mode and restores PATH.
##
mock_sandbox_disable() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local saved="${dir}/.sandbox/path"

  if [ ! -e "${saved}" ]; then
    flunk "Mock sandbox is not enabled. Enable it with 'mock_sandbox_enable' first."
    return 1
  fi

  PATH="$(cat "${saved}")"
  rm -f "${saved}"

  unset -f command_not_found_handle
  export -fn mock_sandbox_deny
  unset BATS_HELPERS_MOCK_SANDBOX_REPORT

  mock_path_record
}

##
# Reports whether the sandbox mode is enabled.
##
mock_sandbox_enabled() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  [ -e "${dir}/.sandbox/path" ]
}

##
# Prints what left the mock boundary.
#
# Arguments:
#   1. kind: 'denied' for the commands the sandbox did not resolve, 'allowed'
#      for the ones it let run for real. Optional, defaults to both.
#
# Outputs:
#   STDOUT: One line per command, each named once, in the order the commands
#           were first seen.
##
mock_sandbox_report() {
  local kind="${1-}"

  case "${kind}" in
    '' | denied | allowed) ;;
    *)
      flunk "Kind '${kind}' is not known. Use 'denied' or 'allowed'."
      return 1
      ;;
  esac

  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local report="${dir}/.sandbox/report"
  [ -e "${report}" ] || return 0

  local -a seen=()
  local line
  local entry
  local skip

  while IFS= read -r line; do
    [ -n "${kind}" ] && [ "${line%% *}" != "${kind}" ] && continue

    skip=0
    for entry in "${seen[@]}"; do
      [ "${entry}" = "${line}" ] && skip=1
    done

    [ "${skip}" = "1" ] && continue

    seen+=("${line}")

    case "${line}" in
      denied\ *) echo "Command '${line#denied }' is not mocked and the mock sandbox denied it" ;;
      *) echo "Command '${line#allowed }' ran for real, allowed by the mock sandbox" ;;
    esac
  done <"${report}"

  return 0
}

##
# Records a command the sandbox did not resolve and reports it.
#
# Runs in whichever process hit the failed lookup, where the library is not
# loaded, so it uses builtins alone and must never call 'flunk'.
#
# Arguments:
#   1. name: Command name.
#
# Globals:
#   BATS_HELPERS_MOCK_SANDBOX_REPORT: Path to the report.
#
# Outputs:
#   STDERR: A diagnostic naming the command.
#
# Returns:
#   127 always, the status of a command that was not found.
##
mock_sandbox_deny() {
  local name="${1}"

  if [ -n "${BATS_HELPERS_MOCK_SANDBOX_REPORT-}" ]; then
    printf 'denied %s\n' "${name}" >>"${BATS_HELPERS_MOCK_SANDBOX_REPORT}"
  fi

  printf "Command '%s' is not mocked and the mock sandbox is enabled.\n" "${name}" >&2

  return 127
}

##
# Writes the commands the library and the BATS harness run.
#
# These stay available inside the sandbox, so that the assertions, the file
# helpers, the generated mocks and 'run' itself keep working there. A test that
# needs one of them denied mocks it: the mock directory comes first on PATH and
# shadows the link. 'git' and 'tar' are left out, because a mode that allows
# them by default answers none of the questions it exists to answer.
#
# Outputs:
#   STDOUT: The command names, separated by spaces.
##
mock_sandbox_base_commands() {
  echo 'bash cat chmod cp diff dirname find grep head id ln ls mkdir mktemp rm sed stat touch wc'
}

##
# Links the commands the library and the BATS harness run into the sandbox.
#
# Arguments:
#   1. bin: Directory to link them into.
##
mock_sandbox_link_base() {
  local bin="${1}"

  local real_path
  real_path="$(mock_sandbox_real_path)" || return 1

  local -a names=()
  read -ra names <<<"$(mock_sandbox_base_commands)"

  local name
  local real
  for name in "${names[@]}"; do
    # An allowed command reports what it lets through, so its shim is not
    # replaced by a link that would let the same command through silently.
    [ -e "${bin}/${name}" ] && continue

    real="$(PATH="${real_path}" type -P "${name}")" || real=""

    # A command the machine does not have is nothing to link.
    case "${real}" in
      /*) ln -sf "${real}" "${bin}/${name}" ;;
    esac
  done

  return 0
}

##
# Writes the PATH that the real commands are found on.
#
# The mock directory is dropped from it, so that a command which is both mocked
# and allowed resolves to the real command rather than back into its own mock.
#
# Outputs:
#   STDOUT: The PATH saved when the sandbox was enabled, else the current one,
#           in both cases without the mock directory.
##
mock_sandbox_real_path() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  local saved="${dir}/.sandbox/path"
  local path="${PATH}"

  [ -e "${saved}" ] && path="$(cat "${saved}")"

  mock_forward_path "${dir}" "${path}"
}

##
# Writes the script that runs an allowed command and records the escape.
#
# Arguments:
#   1. shim: Path to write the script to.
#   2. name: Command name.
#   3. real: Path to the real command.
#   4. report: Path to the report.
##
mock_sandbox_write_shim() {
  local shim="${1}"
  local name="${2}"
  local real="${3}"
  local report="${4}"

  # Every value is quoted for the shell rather than interpolated raw, for the
  # same reason 'mock_write' quotes: the directory holding them is
  # consumer-supplied through BATS_HELPERS_MOCK_TMPDIR.
  local name_quoted
  local real_quoted
  local report_quoted
  printf -v name_quoted '%q' "${name}"
  printf -v real_quoted '%q' "${real}"
  printf -v report_quoted '%q' "${report}"

  cat <<EOF >"${shim}"
#!/usr/bin/env bash

printf 'allowed %s\n' ${name_quoted} >>${report_quoted}

exec ${real_quoted} "\$@"
EOF
}

##
## Call log.
##

##
# Writes a value in the canonical serialisation of one call argument.
#
# The value is wrapped in single quotes so that an empty argument stays visible
# and one holding whitespace stays a single field. Inside the quotes a
# backslash reads '\\', a single quote reads '\'', a tab reads '\t' and a
# newline reads '\n', so every argument occupies exactly one line and no two
# distinct arguments serialise the same way.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. value: Argument value. Optional, defaults to an empty string.
#
# Outputs:
#   STDOUT: The quoted value.
##
mock_log_quote() {
  local value="${1-}"

  value="${value//\\/\\\\}"
  value="${value//\'/\\\'}"
  value="${value//$'\t'/\\t}"
  value="${value//$'\n'/\\n}"

  printf "'%s'" "${value}"
}

##
# Writes one call as a log line.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. name: Command name.
#   2+. Arguments the command was called with.
#
# Outputs:
#   STDOUT: The command name followed by every argument, each quoted by
#           'mock_log_quote'.
##
mock_log_line() {
  local name="${1}"
  shift

  local line="${name}"
  local argument

  for argument in "$@"; do
    line="${line} $(mock_log_quote "${argument}")"
  done

  printf '%s\n' "${line}"
}

##
# Appends a line to the call log.
#
# Runs inside the mock's own process, so it must not call 'flunk'.
#
# Arguments:
#   1. log: Path to the log.
#   2. line: Line to append.
##
mock_log_append() {
  local log="${1}"
  local line="${2}"

  printf '%s\n' "${line}" >>"${log}"
}

##
# Resolves the path to the call log.
#
# Globals:
#   BATS_HELPERS_MOCK_TMPDIR: Directory the mocks are stored in.
#
# Outputs:
#   STDOUT: Path to the log, which does not exist until the first call.
##
mock_log_path() {
  local dir
  dir="$(mock_resolve_tmp)" || return 1

  echo "${dir}/mock.log"
}

##
# Prints the call log.
#
# Outputs:
#   STDOUT: Every recorded call, in the order the calls were made, including
#           the ones excluded from sequence comparisons.
##
mock_log_print() {
  local log
  log="$(mock_log_path)" || return 1

  [ -e "${log}" ] || return 0

  cat "${log}"
}

##
# Excludes commands from sequence comparisons.
#
# The calls are still recorded and still visible to 'mock_log_print',
# 'mock_assert_called' and 'mock_assert_not_called'. Only 'mock_assert_calls'
# and 'mock_assert_no_calls' skip them.
#
# Arguments:
#   1+. Command names to exclude.
##
mock_log_exclude() {
  if [ "$#" -eq 0 ]; then
    flunk "At least one command name is required."
    return 1
  fi

  local log
  log="$(mock_log_path)" || return 1

  local name
  for name in "$@"; do
    printf '%s\n' "${name}" >>"${log}.excluded"
  done
}

##
# Prints the call log without the excluded commands.
#
# Outputs:
#   STDOUT: Every recorded call that 'mock_log_exclude' did not exclude.
##
mock_log_filtered() {
  local log
  log="$(mock_log_path)" || return 1

  [ -e "${log}" ] || return 0

  local -a excluded=()
  local name

  if [ -e "${log}.excluded" ]; then
    while IFS= read -r name; do
      [ -n "${name}" ] && excluded+=("${name}")
    done <"${log}.excluded"
  fi

  local line
  local candidate
  local skip

  while IFS= read -r line; do
    skip=0

    for candidate in "${excluded[@]}"; do
      [ "${line%% *}" = "${candidate}" ] && skip=1
    done

    [ "${skip}" = "1" ] && continue

    printf '%s\n' "${line}"
  done <"${log}"

  return 0
}

##
# Prints the recorded calls of one command.
#
# Arguments:
#   1. name: Command name.
#
# Outputs:
#   STDOUT: Every recorded call of the command, in the order the calls were
#           made.
##
mock_log_calls_of() {
  local name="${1}"
  local log
  log="$(mock_log_path)" || return 1

  [ -e "${log}" ] || return 0

  local line
  while IFS= read -r line; do
    [ "${line%% *}" = "${name}" ] && printf '%s\n' "${line}"
  done <"${log}"

  return 0
}

##
# Reports whether a command name belongs to a mock.
#
# Arguments:
#   1. name: Command name.
#
# Returns:
#   0 when a mock is registered under the name, 1 when none is.
##
mock_log_registered() {
  local name="${1}"
  local registered

  while IFS= read -r registered; do
    [ "${registered}" = "${name}" ] && return 0
  done < <(mock_names)

  return 1
}

##
## Call inspection.
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
## Assertions.
##

##
# Asserts that the mocked commands were called in the given order.
#
# Arguments:
#   1+. Expected calls, one per argument, each in the serialisation
#       'mock_log_quote' documents. No arguments asserts that nothing was
#       called.
##
mock_assert_calls() {
  local expected=""

  # The captured log carries no trailing newline, so the expectations are joined
  # without one either and the two are comparable as they stand.
  if [ "$#" -gt 0 ]; then
    printf -v expected '%s\n' "$@"
    expected="${expected%$'\n'}"
  fi

  local actual
  actual="$(mock_log_filtered)" || return 1

  [ "${expected}" = "${actual}" ] && return 0

  format_error "Call log does not match the expected sequence" "expected" "${expected}" "actual" "${actual}" | flunk
}

##
# Asserts that no mocked command was called.
##
mock_assert_no_calls() {
  local actual
  actual="$(mock_log_filtered)" || return 1

  [ -z "${actual}" ] && return 0

  format_error "Mocked commands were called, but none should have been" "calls" "${actual}" | flunk
}

##
# Asserts that a command was called.
#
# Arguments:
#   1. name: Command name.
##
mock_assert_called() {
  local name="${1?'Command name must be specified'}"

  mock_log_registered "${name}" || {
    flunk "Command '${name}' is not mocked. Register it with 'mock_command' first."
    return 1
  }

  local matched
  matched="$(mock_log_calls_of "${name}")" || return 1

  [ -n "${matched}" ] && return 0

  format_error "Command was not called" "command" "${name}" | flunk
}

##
# Asserts that a command was not called.
#
# Arguments:
#   1. name: Command name.
##
mock_assert_not_called() {
  local name="${1?'Command name must be specified'}"

  mock_log_registered "${name}" || {
    flunk "Command '${name}' is not mocked. Register it with 'mock_command' first."
    return 1
  }

  local matched
  matched="$(mock_log_calls_of "${name}")" || return 1

  [ -z "${matched}" ] && return 0

  format_error "Command was called, but should not have been" "command" "${name}" "calls" "${matched}" | flunk
}

##
# Asserts that every expectation of every mock was met.
#
# The sandbox is a property of the test rather than of one mock, so its report
# is covered whichever mocks are named.
#
# Arguments:
#   1+. Mocks to verify. Optional, defaults to every mock of the test.
#
# Outputs:
#   File descriptor 3: The commands the sandbox allowed to run for real, and
#     the warning that PATH changed after 'mock_setup'.
##
mock_verify() {
  local -a mocks=()

  if [ "$#" -gt 0 ]; then
    mocks=("$@")
  else
    mapfile -t mocks < <(mock_paths)
  fi

  local mock
  for mock in "${mocks[@]}"; do
    if [ ! -e "${mock}.call_num" ]; then
      flunk "Mock '${mock}' does not exist. Create it with 'mock_command' first."
      return 1
    fi
  done

  local -a problems=()
  local problem

  for mock in "${mocks[@]}"; do
    while IFS= read -r problem; do
      problems+=("${problem}")
    done < <(mock_verify_mock "${mock}")
  done

  mock_path_check

  # A denied command is a hole in the test, so it fails the verification. An
  # allowed one ran as the test asked it to and only has to stay visible.
  while IFS= read -r problem; do
    problems+=("${problem}")
  done < <(mock_sandbox_report 'denied')

  local escape
  while IFS= read -r escape; do
    echo "${escape}" >&3
  done < <(mock_sandbox_report 'allowed')

  [ "${#problems[@]}" -eq 0 ] && return 0

  local message
  printf -v message '%s\n' "${problems[@]}"

  format_error "Mock expectations were not met" "unmet" "${message%$'\n'}" | flunk
}

##
# Prints the unmet expectations of one mock.
#
# Arguments:
#   1. mock: Path to the mock.
#
# Outputs:
#   STDOUT: One line per unmet expectation, and nothing when all of them
#           were met.
#
# Returns:
#   0 always. An unmet expectation is reported on STDOUT rather than by the
#   exit status.
##
mock_verify_mock() {
  local mock="${1}"

  local name
  name="$(cat "${mock}.name")"

  if [ -e "${mock}.unexpected" ]; then
    local line
    while IFS= read -r line; do
      echo "Mock '${name}' received a call that no expectation covers: ${line}"
    done <"${mock}.unexpected"

    mock_spec_describe_all "${mock}"
  fi

  local call_num
  call_num="$(cat "${mock}.call_num")"

  if [ -e "${mock}.expect_ordinal" ]; then
    local ordinal
    while IFS= read -r ordinal; do
      [ "${ordinal}" -le "${call_num}" ] && continue
      echo "Mock '${name}' has a response configured for call ${ordinal}, but was called ${call_num} time(s)"
    done <"${mock}.expect_ordinal"
  fi

  [ -e "${mock}.spec_num" ] || return 0

  local spec_num
  spec_num="$(cat "${mock}.spec_num")"

  local i
  for ((i = 1; i <= spec_num; i++)); do
    [ "$(cat "${mock}.spec.${i}.hits")" = "0" ] || continue
    echo "Mock '${name}' argument specification ${i} never accepted a call"
  done

  return 0
}

##
## Deprecated aliases, removed in the next version.
##

setup_mock() {
  [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'setup_mock' will be removed in the next version. Use 'mock_setup' instead." >&3
  mock_setup "$@"
}
