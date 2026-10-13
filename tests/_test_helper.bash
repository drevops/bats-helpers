#!/usr/bin/env bash
##
# @file
# Common setup for the library's own tests.
#

# Load library.
load '../load.bash'

setup_file() {
  # Windows shells copy symlinks by default, which turns every `ln -s` fixture
  # (and the sandbox's base-command links) into a regular file. Native symlink
  # mode makes them real links; probe it first, since the privilege is optional.
  case "$(uname)" in
    MINGW* | MSYS* | CYGWIN*)
      # A `setup_file` export does not reach the test processes, so the probe
      # result travels through a per-file marker that `setup()` reads.
      local probe_dir
      probe_dir="$(mktemp -d)"
      if MSYS=winsymlinks:nativestrict ln -s "${probe_dir}" "${probe_dir}-link" 2>/dev/null && [ -h "${probe_dir}-link" ]; then
        touch "${BATS_FILE_TMPDIR}/native_symlinks"
      fi
      rm -rf "${probe_dir}" "${probe_dir}-link"
      ;;
  esac
}

setup() {
  # Windows shells copy symlinks unless native symlink mode is enabled; the
  # probe in setup_file records its result via a marker file (see above).
  if [ -e "${BATS_FILE_TMPDIR}/native_symlinks" ]; then
    export MSYS=winsymlinks:nativestrict
  fi

  # Setup command mocking.
  mock_setup

  # Assertions on the rendered reports compare plain text, so the tests that
  # cover the colour decision itself opt back in rather than out.
  export BATS_HELPERS_REPORT_COLOR=0

  # Print debug information if "--verbose-run" is passed.
  # LCOV_EXCL_START
  if [ "${BATS_VERBOSE_RUN-}" = "1" ]; then
    echo "BATS_TEST_TMPDIR: ${BATS_TEST_TMPDIR}" >&3
  fi
  # LCOV_EXCL_STOP
}

teardown() {
  cleanup_run
}
