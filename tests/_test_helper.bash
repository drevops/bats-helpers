#!/usr/bin/env bash
##
# @file
# Bats test helpers.
#
# shellcheck disable=SC2119,SC2120,SC2044,SC2294

# Guard against bats executing this twice
if [ -z "$TEST_PATH_INITIALIZED" ]; then
  export TEST_PATH_INITIALIZED=true

  # Add BATS test directory to the PATH.
  PATH="$(dirname "${BATS_TEST_DIRNAME}"):$PATH"

  # BATS_TMPDIR - the location to a directory that may be used to store
  # temporary files. Provided by bats. Created once for the duration of whole
  # suite run.
  # Do not use BATS_TMPDIR, instead use BATS_TEST_TMPDIR.
  #
  # BATS_TEST_TMPDIR - unique location for temp files per test.
  # shellcheck disable=SC2002
  random_suffix=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)
  BATS_TEST_TMPDIR="${BATS_RUN_TMPDIR}/bats-test-tmp-${random_suffix}"
  [ -d "${BATS_TEST_TMPDIR}" ] && rm -Rf "${BATS_TEST_TMPDIR}" >/dev/null
  mkdir -p "${BATS_TEST_TMPDIR}"

  export BATS_TEST_TMPDIR

  echo "BATS_TEST_TMPDIR dir: ${BATS_TEST_TMPDIR}" >&3
fi

# Load library.
load '../load.bash'
