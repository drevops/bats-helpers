#!/usr/bin/env bash
##
# @file
# Argument specifications that select which response a mock returns.
#
# Every function below the "Matching" banner runs inside the mock's own
# process, where the assertion helpers are not loaded, so none of them may call
# 'flunk'.
#

##
## Configuration.
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

  echo -e "${property_value}" >"${spec}.${property_name}"
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
# Arguments:
#   1. mock: Path to the mock.
#   2. name: Command name.
#   3+. Arguments the command was called with.
#
# Outputs:
#   STDERR: A diagnostic when the real command is not on PATH.
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
# Arguments:
#   1. dir: Directory to remove.
#
# Outputs:
#   STDOUT: The remaining PATH entries.
##
mock_forward_path() {
  local dir="${1}"
  local -a entries=()
  local -a kept=()

  IFS=':' read -ra entries <<<"${PATH}"

  local entry
  for entry in "${entries[@]}"; do
    [ "${entry}" = "${dir}" ] && continue
    kept+=("${entry}")
  done

  local joined
  printf -v joined '%s:' "${kept[@]}"

  echo "${joined%:}"
}
