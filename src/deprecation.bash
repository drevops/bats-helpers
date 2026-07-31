#!/usr/bin/env bash
#
# A Bats helper library for announcing deprecated functions.
#

##
# Announce that a function has been renamed.
#
# The notice is printed once per deprecated name per test run, so a deprecated
# function called in a loop does not flood the output.
#
# Arguments:
#   1. old_name: The deprecated function name.
#   2. new_name: The replacement function name.
#
# Global Variables:
#   BATS_DEPRECATION_NOTICE_ENABLED: Set to '0' to suppress notices. Defaults to '1'.
#   BATS_DEPRECATION_NOTICE_SEEN: Names already announced in the current shell.
#
# Outputs:
#   FD3: The notice, when the descriptor is open.
#   STDERR: The notice, when the descriptor is not open.
#
# Examples:
#   assert_dir_contains_string() {
#     deprecated "assert_dir_contains_string" "assert_dir_contains"
#     assert_dir_contains "$@"
#   }
##

deprecated() {
  local old_name="${1:?'Deprecated name must be specified'}"
  local new_name="${2:?'Replacement name must be specified'}"

  if [ "${BATS_DEPRECATION_NOTICE_ENABLED:-1}" != "1" ]; then
    return 0
  fi

  case " ${BATS_DEPRECATION_NOTICE_SEEN-} " in
    *" ${old_name} "*) return 0 ;;
  esac

  BATS_DEPRECATION_NOTICE_SEEN="${BATS_DEPRECATION_NOTICE_SEEN-}${old_name} "

  # Bats runs every test in its own subshell, so the variable above cannot
  # carry a name across tests, while a marker file in the suite-wide temporary
  # directory can. The directory is created and removed per run, which scopes
  # the markers to exactly one run.
  local marker_dir
  local marker

  if [ -n "${BATS_SUITE_TMPDIR-}" ]; then
    marker_dir="${BATS_SUITE_TMPDIR}/bats-helpers-deprecated"
    marker="${marker_dir}/${old_name//[^a-zA-Z0-9_.-]/_}"

    # Creating a directory is atomic, so parallel jobs racing on the same name
    # produce exactly one notice between them.
    if mkdir -p "${marker_dir}" 2>/dev/null; then
      if ! mkdir "${marker}" 2>/dev/null; then
        return 0
      fi
    fi
  fi

  local message="# Deprecated: '${old_name}' will be removed in the next version of bats-helpers. Use '${new_name}' instead."

  # Descriptor 3 is the only stream that Bats leaves out of both 'run' capture
  # and command substitution, so functions returning a value through STDOUT
  # keep returning it intact.
  if { true >&3; } 2>/dev/null; then
    echo "${message}" >&3
    return 0
  fi

  echo "${message}" >&2

  return 0
}
