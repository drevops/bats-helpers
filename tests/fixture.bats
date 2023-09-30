#!/usr/bin/env bats
#
# BATS tests for Fixture helpers.
#

load _test_helper

@test "Codebase export not enabled" {
  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"
  fixture_export_codebase "${build_dir}"
  assert_file_not_exists "${build_dir}/README.md"
}

@test "Codebase export enabled" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"
  fixture_export_codebase "${build_dir}"
  assert_file_exists "${build_dir}/README.md"
}
