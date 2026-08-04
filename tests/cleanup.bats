#!/usr/bin/env bats
#
# Tests for deferred cleanup.
#

load _test_helper

@test "cleanup_register and cleanup_run" {
  cleanup_register touch "${BATS_TEST_TMPDIR}/marker"

  assert_file_not_exists "${BATS_TEST_TMPDIR}/marker"

  cleanup_run

  assert_file_exists "${BATS_TEST_TMPDIR}/marker"
}

@test "cleanup_run in reverse order of registration" {
  cleanup_register echo "third"
  cleanup_register echo "second"
  cleanup_register echo "first"

  run cleanup_run
  assert_success
  assert_output "first
second
third"
}

@test "cleanup_run without registrations" {
  assert_file_not_exists "$(cleanup_registry_path)"

  run cleanup_run
  assert_success
  assert_output ""
}

@test "cleanup_run twice" {
  cleanup_register touch "${BATS_TEST_TMPDIR}/marker"

  cleanup_run
  assert_file_exists "${BATS_TEST_TMPDIR}/marker"

  rm -f "${BATS_TEST_TMPDIR}/marker"

  cleanup_run
  assert_file_not_exists "${BATS_TEST_TMPDIR}/marker"
}

@test "cleanup_register without a command" {
  run cleanup_register
  assert_failure
  assert_output_contains "Cleanup command is required."

  assert_file_not_exists "$(cleanup_registry_path)"
}

@test "cleanup_register from a subshell" {
  run cleanup_register touch "${BATS_TEST_TMPDIR}/marker"
  assert_success

  cleanup_run

  assert_file_exists "${BATS_TEST_TMPDIR}/marker"
}

@test "cleanup_register preserves arguments verbatim" {
  local dir="${BATS_TEST_TMPDIR}/dir with spaces"
  mkdir -p "${dir}"

  cleanup_register touch "${dir}/file with spaces.txt"
  cleanup_register touch "${dir}/*"
  cleanup_register touch "${dir}/quote'd.txt"

  cleanup_run

  run ls "${dir}"
  assert_success
  assert_output_contains "file with spaces.txt"
  assert_output_contains "*"
  assert_output_contains "quote'd.txt"
}

# A newline that was not escaped would split the registration across two lines
# of the registry, so the two words would come back reversed or not at all.
@test "cleanup_register preserves a newline in an argument" {
  cleanup_register echo "one
two"

  run cleanup_run
  assert_success
  assert_output "one
two"
}

@test "cleanup_run with a failing command" {
  cleanup_register false

  run cleanup_run
  assert_failure
  assert_output_contains "Cleanup command 'false' failed with exit status 1."
}

@test "cleanup_run continues past a failing command" {
  cleanup_register touch "${BATS_TEST_TMPDIR}/first.marker"
  cleanup_register bash -c "exit 3"
  cleanup_register touch "${BATS_TEST_TMPDIR}/last.marker"

  run cleanup_run
  assert_failure
  assert_output_contains "failed with exit status 3"

  assert_file_exists "${BATS_TEST_TMPDIR}/first.marker"
  assert_file_exists "${BATS_TEST_TMPDIR}/last.marker"
}

@test "cleanup_registry_path" {
  run cleanup_registry_path
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/bats-helpers-cleanup"
}

@test "cleanup_registry_path with a custom directory" {
  export BATS_HELPERS_CLEANUP_DIR="${BATS_TEST_TMPDIR}/custom"

  run cleanup_registry_path
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/bats-helpers-cleanup"

  # A trailing slash does not produce a double separator.
  export BATS_HELPERS_CLEANUP_DIR="${BATS_TEST_TMPDIR}/custom/"

  run cleanup_registry_path
  assert_success
  assert_output "${BATS_TEST_TMPDIR}/custom/bats-helpers-cleanup"
}

@test "cleanup_register and cleanup_run in a custom directory" {
  export BATS_HELPERS_CLEANUP_DIR="${BATS_TEST_TMPDIR}/custom"

  cleanup_register touch "${BATS_TEST_TMPDIR}/marker"

  assert_file_exists "${BATS_TEST_TMPDIR}/custom/bats-helpers-cleanup"
  assert_file_not_exists "${BATS_TEST_TMPDIR}/bats-helpers-cleanup"

  cleanup_run

  assert_file_exists "${BATS_TEST_TMPDIR}/marker"
}

@test "cleanup_registry_path without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_TEST_TMPDIR=""
  run cleanup_registry_path
  BATS_TEST_TMPDIR="${original}"

  assert_failure
}

@test "cleanup_register without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_TEST_TMPDIR=""
  run cleanup_register touch "${original}/marker"
  BATS_TEST_TMPDIR="${original}"

  assert_failure
  assert_file_not_exists "${original}/marker"
}

@test "cleanup_run without a sandbox" {
  local original="${BATS_TEST_TMPDIR}"

  BATS_TEST_TMPDIR=""
  run cleanup_run
  BATS_TEST_TMPDIR="${original}"

  assert_failure
}

# The two tests below share one registry location, because with the per-test
# default nothing could leak between them in the first place.
@test "cleanup registrations do not leak into the next test" {
  export BATS_HELPERS_CLEANUP_DIR="${BATS_FILE_TMPDIR}"

  cleanup_register touch "${BATS_FILE_TMPDIR}/leak.marker"

  assert_file_exists "$(cleanup_registry_path)"
  assert_file_not_exists "${BATS_FILE_TMPDIR}/leak.marker"
}

@test "cleanup registrations do not leak into the next test - next test" {
  export BATS_HELPERS_CLEANUP_DIR="${BATS_FILE_TMPDIR}"

  assert_file_exists "${BATS_FILE_TMPDIR}/leak.marker"
  assert_file_not_exists "$(cleanup_registry_path)"
}

@test "cleanup_run from teardown after a passing test" {
  cleanup_fixture_run "passing test with a cleanup"

  assert_success
  assert_output_contains "ok 1 passing test with a cleanup"
  assert_file_exists "${CLEANUP_FIXTURE_DIR}/passing.marker"
}

@test "cleanup_run from teardown after a failing test" {
  cleanup_fixture_run "failing test with a cleanup"

  assert_failure
  assert_output_contains "not ok 1 failing test with a cleanup"
  assert_file_exists "${CLEANUP_FIXTURE_DIR}/failing.marker"
}

@test "cleanup_run from teardown fails an otherwise-passing test" {
  cleanup_fixture_run "passing test with a failing cleanup"

  assert_failure
  assert_output_contains "not ok 1 passing test with a failing cleanup"
  assert_output_contains "from function \`teardown'"
  assert_output_contains "Cleanup command 'false' failed with exit status 1."
}

@test "cleanup_run from teardown does not mask a preceding failure" {
  cleanup_fixture_run "failing test with a failing cleanup"

  assert_failure
  assert_output_contains "not ok 1 failing test with a failing cleanup"
  # The reported failure is the test's own, not the one raised in teardown.
  assert_output_not_contains "from function \`teardown'"
  assert_output_contains "Cleanup command 'false' failed with exit status 1."
}

##
# Runs one test of the teardown fixture in a nested BATS process.
#
# Filtering down to a single test keeps the captured output specific to the
# scenario the caller names.
#
# Arguments:
#   1. name: Name of the fixture test to run.
#
# Globals:
#   CLEANUP_FIXTURE_DIR: Set to the directory the fixture writes its markers to.
##
cleanup_fixture_run() {
  export CLEANUP_FIXTURE_DIR="${BATS_TEST_TMPDIR}/fixture"
  mkdir -p "${CLEANUP_FIXTURE_DIR}"

  run "${BATS_ROOT}/bin/bats" --tap --filter "^${1}\$" "${BATS_TEST_DIRNAME}/fixtures/cleanup_teardown.bats"
}
