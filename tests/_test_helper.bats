# Tests for the platform logic in _test_helper.bash. The platform branches are
# exercised on every OS by stubbing `uname`, so coverage does not depend on
# which machine runs the suite.

# The platform and link stubs are invoked indirectly by the code under test.
# shellcheck disable=SC2329

load _test_helper

setup() {
  # Isolate from the marker the real setup_file may have written for this file.
  _test_helper_saved_file_tmpdir="${BATS_FILE_TMPDIR}"
  BATS_FILE_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${BATS_FILE_TMPDIR}"
  BATS_FILE_TMPDIR="${_test_helper_saved_file_tmpdir}"
  unset -f uname ln 2>/dev/null || true
}

@test "_test_helper_probe_native_symlinks records the marker when native links work" {
  uname() {
    echo MINGW64_NT-10.0
  }

  _test_helper_probe_native_symlinks

  assert_file_exists "${BATS_FILE_TMPDIR}/native_symlinks"
}

@test "_test_helper_probe_native_symlinks records nothing when the link is refused" {
  uname() {
    echo MINGW64_NT-10.0
  }
  ln() {
    return 1
  }

  _test_helper_probe_native_symlinks

  assert_file_not_exists "${BATS_FILE_TMPDIR}/native_symlinks"
}

@test "_test_helper_probe_native_symlinks does nothing off Windows" {
  uname() {
    echo Linux
  }

  _test_helper_probe_native_symlinks

  assert_file_not_exists "${BATS_FILE_TMPDIR}/native_symlinks"
}
