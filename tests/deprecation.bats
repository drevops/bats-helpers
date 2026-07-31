#!/usr/bin/env bats
#
# BATS tests for deprecation helpers.
#
# Every test uses a deprecated name of its own: notices are deduplicated for
# the whole suite run, so a shared name would make one test silence another.
#

load _test_helper

@test "Notice names both functions" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  deprecated "old_content" "new_content" 3>"${notice}"

  assert_file_contains "${notice}" "old_content"
  assert_file_contains "${notice}" "new_content"
  assert_file_contains "${notice}" "will be removed in the next version of bats-helpers"
}

@test "Notice is not printed to stdout" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  captured="$(deprecated "old_stdout" "new_stdout" 3>"${notice}")"

  assert_empty "${captured}"
  assert_file_contains "${notice}" "old_stdout"
}

@test "Notice is printed once per name" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  deprecated "old_repeated" "new_repeated" 3>"${notice}"
  deprecated "old_repeated" "new_repeated" 3>>"${notice}"
  deprecated "old_repeated" "new_repeated" 3>>"${notice}"

  assert_equal "1" "$(grep -c "old_repeated" "${notice}")"
}

@test "Notice is printed for every name" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  deprecated "old_first" "new_first" 3>"${notice}"
  deprecated "old_second" "new_second" 3>>"${notice}"

  assert_file_contains "${notice}" "old_first"
  assert_file_contains "${notice}" "old_second"
}

@test "Notice is printed once across processes" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  script="${BATS_TEST_TMPDIR}/shared.sh"

  echo "export BATS_SUITE_TMPDIR='${BATS_SUITE_TMPDIR}'" >"${script}"
  echo "source '${BATS_TEST_DIRNAME}/../load.bash'" >>"${script}"
  echo "deprecated 'old_shared' 'new_shared'" >>"${script}"

  bash "${script}" 3>"${notice}"
  bash "${script}" 3>>"${notice}"

  assert_equal "1" "$(grep -c "old_shared" "${notice}")"
}

@test "Notice is printed without a suite temporary directory" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"
  script="${BATS_TEST_TMPDIR}/unshared.sh"

  echo "unset BATS_SUITE_TMPDIR" >"${script}"
  echo "source '${BATS_TEST_DIRNAME}/../load.bash'" >>"${script}"
  echo "deprecated 'old_unshared' 'new_unshared'" >>"${script}"

  bash "${script}" 3>"${notice}"
  bash "${script}" 3>>"${notice}"

  assert_equal "2" "$(grep -c "old_unshared" "${notice}")"
}

@test "Notice is suppressed" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  BATS_DEPRECATION_NOTICE_ENABLED=0 deprecated "old_suppressed" "new_suppressed" 3>"${notice}"

  assert_file_exists "${notice}"
  assert_empty "$(cat "${notice}")"
}

@test "Notice falls back to stderr" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  deprecated "old_stderr" "new_stderr" 3>&- 2>"${notice}"

  assert_file_contains "${notice}" "old_stderr"
}

@test "Notice does not alter the exit status" {
  notice="${BATS_TEST_TMPDIR}/notice.txt"

  deprecated "old_status" "new_status" 3>"${notice}"
  assert_equal "0" "$?"

  deprecated "old_status" "new_status" 3>>"${notice}"
  assert_equal "0" "$?"
}

@test "Notice requires both names" {
  script="${BATS_TEST_TMPDIR}/incomplete.sh"

  echo "source '${BATS_TEST_DIRNAME}/../load.bash'" >"${script}"
  # shellcheck disable=SC2016
  echo 'deprecated "${@}"' >>"${script}"

  run bash "${script}"
  assert_failure

  run bash "${script}" "old_incomplete"
  assert_failure

  run bash "${script}" "" "new_incomplete"
  assert_failure

  run bash "${script}" "old_incomplete" ""
  assert_failure
}
