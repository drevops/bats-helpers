#!/usr/bin/env bats
#
# Tests for fixture helpers.
#
# shellcheck disable=SC2030,SC2031,SC2016

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

@test "Codebase export - missing destination directory" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/non-existing"

  run fixture_export_codebase "${build_dir}"
  assert_failure
  # 'flunk' rewrites the temporary directory path to a literal placeholder.
  assert_output_contains "Directory '\${BATS_TEST_TMPDIR}/non-existing' does not exist"
}

@test "Codebase export - missing destination directory - caller recovers" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/non-existing"

  recovered=0
  fixture_export_codebase "${build_dir}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Codebase export - export fails" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  # A repository without commits has no HEAD, so 'git archive' fails.
  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-no-commits"
  fixture_prepare_dir "${src_dir}"
  git -C "${src_dir}" init --quiet

  run fixture_export_codebase "${build_dir}" "${src_dir}"
  assert_failure
  assert_output_contains "Failed to export codebase"
}

@test "Codebase export - export fails - caller recovers" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-no-commits"
  fixture_prepare_dir "${src_dir}"
  git -C "${src_dir}" init --quiet

  recovered=0
  fixture_export_codebase "${build_dir}" "${src_dir}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Codebase export - source is not a git repository" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-not-a-repo"
  fixture_prepare_dir "${src_dir}"

  run fixture_export_codebase "${build_dir}" "${src_dir}"
  assert_failure
  # 'flunk' rewrites the temporary directory path to a literal placeholder.
  assert_output_contains "Directory '\${BATS_TEST_TMPDIR}/src-not-a-repo' is not a git repository"
}

@test "Codebase export - source is not a git repository - caller recovers" {
  export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

  build_dir="${BATS_TEST_TMPDIR//\/\//\/}/build-$(date +%s)"
  fixture_prepare_dir "${build_dir}"

  src_dir="${BATS_TEST_TMPDIR//\/\//\/}/src-not-a-repo"
  fixture_prepare_dir "${src_dir}"

  recovered=0
  fixture_export_codebase "${build_dir}" "${src_dir}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}
