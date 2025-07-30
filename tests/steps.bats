#!/usr/bin/env bats
#
# Tests for steps helper.
#
# shellcheck disable=SC2034,SC2030,SC2031,SC2016

load _test_helper

@test "Substring presence" {
  declare -a STEPS=(
    "Some Substring"
  )

  # Shorthand.
  run echo "Some Substring"
  run_steps

  # Full.
  run_steps "setup"
  run echo "Some Substring"
  run_steps "assert"

  # Full with mocks
  mocks="$(run_steps "setup")"
  run echo "Some Substring"
  run_steps "assert" "${mocks[@]}"

  # Negative.
  run echo "Some other"
  run run_steps "assert"
  assert_failure
}

@test "Substring absence" {
  declare -a STEPS=(
    "- Some Substring"
  )

  # Shorthand.
  run echo "Some other"
  run_steps

  # Full.
  run_steps "setup"
  run echo "Some other"
  run_steps "assert"

  # Full with mocks
  mocks="$(run_steps "setup")"
  run echo "Some other"
  run_steps "assert" "${mocks[@]}"

  # Negative.
  run echo "Some Substring"
  run run_steps "assert"
  assert_failure
}

@test "Direct command execution" {
  declare -a STEPS=(
    "@somebin # 0 # someval"
  )

  mocks="$(run_steps "setup")"
  somebin
  run_steps "assert" "${mocks[@]}"
}

@test "Direct command execution, args" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(run_steps "setup")"
  somebin --opt1 --opt2
  run_steps "assert" "${mocks[@]}"
}

@test "Wrapped execution through Bat's 'run'" {
  declare -a STEPS=(
    "@somebin # 0 # someval"
  )

  mocks="$(run_steps "setup")"
  run somebin
  assert_output_contains "someval"
  run_steps "assert" "${mocks[@]}"
}

@test "Command, args" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1 --opt2
  assert_output_contains "someval"
  run_steps "assert" "${mocks[@]}"
}

@test "Command, args - negative: wrong args" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1 --opt2 --opt3
  assert_output_contains "someval"

  run run_steps "assert" "${mocks[@]}"
  assert_failure
}

@test "Command, args, no exit code or output" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1 --opt2

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, args, output, no exit code" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # someval with spaces"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1 --opt2
  assert_output_contains "someval with spaces"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, args, error exit code" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 1 # someval with spaces"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1 --opt2
  assert_failure
  assert_output_contains "someval with spaces"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, args - negative: incorrect input - delim" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 ## someval"
  )

  run run_steps "setup" "${mocks[@]}"
  assert_failure
  assert_output_contains "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
}

@test "Command, multiple commands, same, repeated call" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(run_steps "setup")"

  run somebin --opt1 --opt2
  assert_output_contains "someval1 with spaces"
  assert_output_not_contains "someval2 with spaces"
  run somebin --opt1 --opt2
  assert_output_not_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multiple commands, same, combined execution" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(run_steps "setup")"

  run bash -c "somebin --opt1 --opt2; somebin --opt1 --opt2"
  assert_output_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multiple commands, same, combined execution, and" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(run_steps "setup")"

  run bash -c "somebin --opt1 --opt2 && somebin --opt1 --opt2"
  assert_output_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multiple commands, different" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@otherbin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(run_steps "setup")"

  run somebin
  assert_success
  run otherbin
  assert_success

  run run_steps "assert" "${mocks[@]}"

}

@test "Command, multiple commands, different - negative: incorrect call order" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@otherbin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(run_steps "setup")"
  run otherbin
  assert_success
  run somebin
  assert_success

  run run_steps "assert" "${mocks[@]}"
  assert_failure
}

@test "Command, multiple commands, different, repeated call" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
    "@otherbin --opt3 --opt4 # 0 # someval3 with spaces"
  )

  mocks="$(run_steps "setup")"

  run somebin --opt1 --opt2
  assert_output_contains "someval1 with spaces"
  assert_output_not_contains "someval2 with spaces"
  assert_output_not_contains "someval3 with spaces"
  run somebin --opt1 --opt2
  assert_output_not_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"
  assert_output_not_contains "someval3 with spaces"
  run otherbin --opt3 --opt4
  assert_output_not_contains "someval1 with spaces"
  assert_output_not_contains "someval2 with spaces"
  assert_output_contains "someval3 with spaces"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multiple commands, different, repeated call - negative" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
    "@otherbin --opt3 --opt4 # 0 # someval3 with spaces"
  )

  mocks="$(run_steps "setup")"

  run somebin --opt1 --opt2
  assert_output_contains "someval1 with spaces"
  assert_output_not_contains "someval2 with spaces"
  assert_output_not_contains "someval3 with spaces"
  run somebin --opt1 --opt2
  assert_output_not_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"
  assert_output_not_contains "someval3 with spaces"

  # Asserting missing call to the 'otherbin'.
  run run_steps "assert" "${mocks[@]}"
  assert_failure
}

@test "Command, multiple commands, different, repeated call, order" {
  declare -a STEPS=(
    "@somebin --opt11 --opt21 # 0 # someval1 with spaces"
    "@somebin --opt11 --opt22 # 0 # someval2 with spaces"
    "@otherbin --opt31 --opt41 # 0 # someval3 with spaces"
    "@somebin --opt13 --opt23 # 0 # someval4 with spaces"
    "@otherbin --opt32 --opt42 # 0 # someval5 with spaces"
    "@otherbin --opt33 --opt43 # 0 # someval6 with spaces"
  )

  mocks="$(run_steps "setup")"

  run somebin --opt11 --opt21
  run somebin --opt11 --opt22
  run otherbin --opt31 --opt41
  run somebin --opt13 --opt23
  run otherbin --opt32 --opt42
  run otherbin --opt33 --opt43

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multiple commands, different, repeated call, order - negative" {
  declare -a STEPS=(
    "@somebin --opt11 --opt21 # 0 # someval1 with spaces"
    "@somebin --opt11 --opt22 # 0 # someval2 with spaces"
    "@otherbin --opt31 --opt41 # 0 # someval3 with spaces"
    "@somebin --opt13 --opt23 # 0 # someval4 with spaces"
    "@otherbin --opt32 --opt42 # 0 # someval5 with spaces"
    "@otherbin --opt33 --opt43 # 0 # someval6 with spaces"
  )

  mocks="$(run_steps "setup")"

  run somebin --opt11 --opt21
  run somebin --opt13 --opt23
  run somebin --opt11 --opt22
  run otherbin --opt32 --opt42
  run otherbin --opt31 --opt41
  run otherbin --opt33 --opt43

  run run_steps "assert" "${mocks[@]}"
  assert_failure
}

@test "Command, multiple commands, different, combined, repeated call, order" {
  # To assert string presence/absence without creating a script that prints
  # strings, we use the output of commands.
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
    "someval2 with spaces"
    "- absent someval21 with spaces"
    "@somebin --opt1 --opt2 --opt3 # 0 # someval3 with spaces"
    "someval3 with spaces"
    "@otherbin --opt1 --opt2 --opt3 # 0 # someval4 with spaces"
    "@otherbin --opt1 --opt2 --opt3 # 0 # someval5 with spaces"
    "- absent someval5 with spaces"
  )

  mocks="$(run_steps "setup")"

  run bash -c "somebin --opt1 --opt2; somebin --opt1 --opt2; somebin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multiple commands, different, combined, repeated call, order, shorthand" {
  # To assert string presence/absence without creating a script that prints
  # strings, we use the output of commands.
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # someval1 with spaces"
    "someval1 with spaces"
    "@somebin --opt1 --opt2 # someval2 with spaces"
    "someval2 with spaces"
    "- absent someval21 with spaces"
    "@somebin --opt1 --opt2 --opt3 # someval3 with spaces"
    "someval3 with spaces"
    "@otherbin --opt1 --opt2 --opt3 # someval4 with spaces"
    "@otherbin --opt1 --opt2 --opt3 # someval5 with spaces"
    "- absent someval5 with spaces"
  )

  mocks="$(run_steps "setup")"

  run bash -c "somebin --opt1 --opt2; somebin --opt1 --opt2; somebin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3"

  run run_steps "assert" "${mocks[@]}"
  assert_success
}

@test "Command, multi-line argument" {
  declare -a STEPS=(
    "@somebin --opt1 \
    --opt2 \
      --opt3 \
  { \
  test: 1 \
  }
    # 0 # multi-line arg"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1 \
    --opt2 \
    --opt3 \
    "{" \
    "test": 1 \
    "}"
  run run_steps "assert" "${mocks[@]}"
  assert_success

}

@test "Command with side effect - basic file creation" {
  declare -a STEPS=(
    '@somebin --opt1 # 0 # success # touch ${BATS_TEST_TMPDIR}/side_effect_file'
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/side_effect_file"
}

@test "Command with side effect - environment variable" {
  declare -a STEPS=(
    "@somebin --opt1 # 0 # success # export TEST_SIDE_EFFECT=executed"
  )

  mocks="$(run_steps "setup")"

  # Side effects are executed in the mock's context, not the test context
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  run_steps "assert" "${mocks[@]}"
}

@test "Command with side effect - echo to file" {
  declare -a STEPS=(
    "@somebin --opt1 # 0 # success # echo 'side effect executed' > \${BATS_TEST_TMPDIR}/side_effect_output"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify side effect output
  assert_file_exists "${BATS_TEST_TMPDIR}/side_effect_output"
  run cat "${BATS_TEST_TMPDIR}/side_effect_output"
  assert_output_contains "side effect executed"
}

@test "Command with side effect - multiple commands" {
  declare -a STEPS=(
    "@somebin --opt1 # 0 # success # touch \${BATS_TEST_TMPDIR}/file1; echo 'data' > \${BATS_TEST_TMPDIR}/file2"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify both side effects were executed
  assert_file_exists "${BATS_TEST_TMPDIR}/file1"
  assert_file_exists "${BATS_TEST_TMPDIR}/file2"
  run cat "${BATS_TEST_TMPDIR}/file2"
  assert_output_contains "data"
}

@test "Command with side effect - exit status and output" {
  declare -a STEPS=(
    "@somebin --opt1 # 1 # error message # echo 'error logged' > \${BATS_TEST_TMPDIR}/error_log"
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1
  assert_output_contains "error message"
  assert_failure

  run_steps "assert" "${mocks[@]}"

  # Verify side effect was executed even with failure status
  assert_file_exists "${BATS_TEST_TMPDIR}/error_log"
  run cat "${BATS_TEST_TMPDIR}/error_log"
  assert_output_contains "error logged"
}

@test "Command with side effect - no output, only side effect" {
  declare -a STEPS=(
    '@somebin --opt1 # 0 # # touch ${BATS_TEST_TMPDIR}/no_output_side_effect'
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/no_output_side_effect"
}

@test "Command with side effect - shorthand status with side effect" {
  declare -a STEPS=(
    '@somebin --opt1 # success output # # touch ${BATS_TEST_TMPDIR}/shorthand_side_effect'
  )

  mocks="$(run_steps "setup")"
  run somebin --opt1
  assert_output_contains "success output"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/shorthand_side_effect"
}

@test "Multiple commands with different side effects" {
  declare -a STEPS=(
    '@cmd1 # 0 # output1 # touch ${BATS_TEST_TMPDIR}/cmd1_file'
    "@cmd2 # 0 # output2 # echo 'cmd2 executed' > \${BATS_TEST_TMPDIR}/cmd2_file"
  )

  mocks="$(run_steps "setup")"

  run cmd1
  assert_output_contains "output1"
  assert_success

  run cmd2
  assert_output_contains "output2"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify both side effects were executed
  assert_file_exists "${BATS_TEST_TMPDIR}/cmd1_file"
  assert_file_exists "${BATS_TEST_TMPDIR}/cmd2_file"
  run cat "${BATS_TEST_TMPDIR}/cmd2_file"
  assert_output_contains "cmd2 executed"
}

@test "Command with side effect - repeated calls with different side effects" {
  declare -a STEPS=(
    '@somebin # 0 # call1 # touch ${BATS_TEST_TMPDIR}/call1_file'
    '@somebin # 0 # call2 # touch ${BATS_TEST_TMPDIR}/call2_file'
  )

  mocks="$(run_steps "setup")"

  run somebin
  assert_output_contains "call1"
  assert_success

  run somebin
  assert_output_contains "call2"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify both side effects were executed
  assert_file_exists "${BATS_TEST_TMPDIR}/call1_file"
  assert_file_exists "${BATS_TEST_TMPDIR}/call2_file"
}

@test "Command with side effect - error in parsing too many separators" {
  declare -a STEPS=(
    "@somebin # 0 # output # side effect # extra"
  )

  run run_steps "setup"
  assert_failure
  assert_output_contains "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
}

@test "Command with side effect - consecutive ## still forbidden" {
  declare -a STEPS=(
    "@somebin # 0 ## output # side effect"
  )

  run run_steps "setup"
  assert_failure
  assert_output_contains "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
}

@test "Wildcard command - any arguments accepted" {
  declare -a STEPS=(
    "@somebin * # 0 # wildcard output 1"
    "@somebin * # 0 # wildcard output 2"
    "@somebin * # 0 # wildcard output 3"
  )

  mocks="$(run_steps "setup")"

  # Test with different arguments - all should work
  run somebin --opt1 --opt2
  assert_output_contains "wildcard output 1"
  assert_success

  run somebin completely different args
  assert_output_contains "wildcard output 2"
  assert_success

  run somebin
  assert_output_contains "wildcard output 3"
  assert_success

  run_steps "assert" "${mocks[@]}"
}

@test "Wildcard command - multiple calls with different args" {
  declare -a STEPS=(
    "@git * # 0 # git output 1"
    "@git * # 0 # git output 2"
  )

  mocks="$(run_steps "setup")"

  run git status
  assert_output_contains "git output 1"
  assert_success

  run git commit -m "test"
  assert_output_contains "git output 2"
  assert_success

  run_steps "assert" "${mocks[@]}"
}

@test "Wildcard command - with side effects" {
  declare -a STEPS=(
    '@somebin * # 0 # wildcard success # touch ${BATS_TEST_TMPDIR}/wildcard_file'
  )

  mocks="$(run_steps "setup")"

  run somebin any args here
  assert_output_contains "wildcard success"
  assert_success

  run_steps "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/wildcard_file"
}

@test "Wildcard command - error status" {
  declare -a STEPS=(
    "@somebin * # 1 # wildcard error"
  )

  mocks="$(run_steps "setup")"

  run somebin any args
  assert_output_contains "wildcard error"
  assert_failure

  run_steps "assert" "${mocks[@]}"
}

@test "Mixed exact and wildcard commands" {
  declare -a STEPS=(
    "@git status # 0 # exact status output"
    "@git * # 0 # wildcard git output"
    "@npm * # 1 # npm error"
  )

  mocks="$(run_steps "setup")"

  # This should match the exact command
  run git status
  assert_output_contains "exact status output"
  assert_success

  # This should match the wildcard
  run git commit -m "test"
  assert_output_contains "wildcard git output"
  assert_success

  # This should match the npm wildcard
  run npm install --save express
  assert_output_contains "npm error"
  assert_failure

  run_steps "assert" "${mocks[@]}"
}

@test "Wildcard command - shorthand syntax" {
  declare -a STEPS=(
    "@somebin * # wildcard shorthand output"
  )

  mocks="$(run_steps "setup")"

  run somebin any arguments
  assert_output_contains "wildcard shorthand output"
  assert_success

  run_steps "assert" "${mocks[@]}"
}
