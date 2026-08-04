#!/usr/bin/env bats
#
# Tests for the step runner.
#
# shellcheck disable=SC2034,SC2030,SC2031,SC2016

load _test_helper

@test "Substring presence" {
  declare -a STEPS=(
    "Some Substring"
  )

  # Shorthand.
  run echo "Some Substring"
  steps_run

  # Full.
  steps_run "setup"
  run echo "Some Substring"
  steps_run "assert"

  # Full with mocks
  mocks="$(steps_run "setup")"
  run echo "Some Substring"
  steps_run "assert" "${mocks[@]}"

  # Negative.
  run echo "Some other"
  run steps_run "assert"
  assert_failure
}

@test "Substring presence - negative: caller recovers" {
  declare -a STEPS=(
    "Some Substring"
  )

  run echo "Some other"

  recovered=0
  steps_run "assert" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Substring absence" {
  declare -a STEPS=(
    "- Some Substring"
  )

  # Shorthand.
  run echo "Some other"
  steps_run

  # Full.
  steps_run "setup"
  run echo "Some other"
  steps_run "assert"

  # Full with mocks
  mocks="$(steps_run "setup")"
  run echo "Some other"
  steps_run "assert" "${mocks[@]}"

  # Negative.
  run echo "Some Substring"
  run steps_run "assert"
  assert_failure
}

@test "Substring absence - negative: caller recovers" {
  declare -a STEPS=(
    "- Some Substring"
  )

  run echo "Some Substring"

  recovered=0
  steps_run "assert" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Direct command execution" {
  declare -a STEPS=(
    "@somebin # 0 # someval"
  )

  mocks="$(steps_run "setup")"
  somebin
  steps_run "assert" "${mocks[@]}"
}

@test "Direct command execution, args" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(steps_run "setup")"
  somebin --opt1 --opt2
  steps_run "assert" "${mocks[@]}"
}

@test "Wrapped execution through Bats' 'run'" {
  declare -a STEPS=(
    "@somebin # 0 # someval"
  )

  mocks="$(steps_run "setup")"
  run somebin
  assert_output_contains "someval"
  steps_run "assert" "${mocks[@]}"
}

@test "Command, args" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1 --opt2
  assert_output_contains "someval"
  steps_run "assert" "${mocks[@]}"
}

@test "Command, args - negative: wrong args" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1 --opt2 --opt3
  assert_output_contains "someval"

  run steps_run "assert" "${mocks[@]}"
  assert_failure
  assert_output_contains "ERROR: Mocked command 'somebin' was called with arguments '--opt1 --opt2 --opt3', but '--opt1 --opt2' was expected."
}

@test "Command, args - negative: wrong args - caller recovers" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1 --opt2 --opt3

  recovered=0
  steps_run "assert" "${mocks[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Command - negative: mock does not exist" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  run steps_run "assert" "otherbin=/some/mock/path"
  assert_failure
  assert_output_contains "ERROR: Mock for the binary 'somebin' does not exist."
}

@test "Command - negative: mock does not exist - caller recovers" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval"
  )

  recovered=0
  steps_run "assert" "otherbin=/some/mock/path" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Command, args, no exit code or output" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1 --opt2

  steps_run "assert" "${mocks[@]}"
}

@test "Command, args, output, no exit code" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # someval with spaces"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1 --opt2
  assert_output_contains "someval with spaces"

  steps_run "assert" "${mocks[@]}"
}

@test "Command, args, error exit code" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 1 # someval with spaces"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1 --opt2
  assert_failure
  assert_output_contains "someval with spaces"

  steps_run "assert" "${mocks[@]}"
}

@test "Command, args - negative: incorrect input - delim" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 ## someval"
  )

  run steps_run "setup" "${mocks[@]}"
  assert_failure
  assert_output_contains "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
}

@test "Command, args - negative: incorrect input - delim - caller recovers" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 ## someval"
  )

  recovered=0
  steps_run "setup" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Command, multiple commands, same, repeated call" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(steps_run "setup")"

  run somebin --opt1 --opt2
  assert_output_contains "someval1 with spaces"
  assert_output_not_contains "someval2 with spaces"
  run somebin --opt1 --opt2
  assert_output_not_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"

  steps_run "assert" "${mocks[@]}"
}

@test "Command, multiple commands, same, combined execution" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(steps_run "setup")"

  run bash -c "somebin --opt1 --opt2; somebin --opt1 --opt2"
  assert_output_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"

  steps_run "assert" "${mocks[@]}"
}

@test "Command, multiple commands, same, combined execution, and" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(steps_run "setup")"

  run bash -c "somebin --opt1 --opt2 && somebin --opt1 --opt2"
  assert_output_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"

  steps_run "assert" "${mocks[@]}"
}

@test "Command, multiple commands, different" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@otherbin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(steps_run "setup")"

  run somebin --opt1 --opt2
  assert_success
  run otherbin --opt1 --opt2
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Command, multiple commands, different - negative: incorrect arguments" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@otherbin --opt1 --opt2 # 0 # someval2 with spaces"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt3 --opt4
  assert_success
  run otherbin --opt1 --opt2
  assert_success

  run steps_run "assert" "${mocks[@]}"
  assert_failure
}

@test "Command, multiple commands, different, repeated call" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
    "@otherbin --opt3 --opt4 # 0 # someval3 with spaces"
  )

  mocks="$(steps_run "setup")"

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

  steps_run "assert" "${mocks[@]}"
}

@test "Command, multiple commands, different, repeated call - negative" {
  declare -a STEPS=(
    "@somebin --opt1 --opt2 # 0 # someval1 with spaces"
    "@somebin --opt1 --opt2 # 0 # someval2 with spaces"
    "@otherbin --opt3 --opt4 # 0 # someval3 with spaces"
  )

  mocks="$(steps_run "setup")"

  run somebin --opt1 --opt2
  assert_output_contains "someval1 with spaces"
  assert_output_not_contains "someval2 with spaces"
  assert_output_not_contains "someval3 with spaces"
  run somebin --opt1 --opt2
  assert_output_not_contains "someval1 with spaces"
  assert_output_contains "someval2 with spaces"
  assert_output_not_contains "someval3 with spaces"

  # Asserting missing call to the 'otherbin'.
  run steps_run "assert" "${mocks[@]}"
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

  mocks="$(steps_run "setup")"

  run somebin --opt11 --opt21
  run somebin --opt11 --opt22
  run otherbin --opt31 --opt41
  run somebin --opt13 --opt23
  run otherbin --opt32 --opt42
  run otherbin --opt33 --opt43

  steps_run "assert" "${mocks[@]}"
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

  mocks="$(steps_run "setup")"

  run somebin --opt11 --opt21
  run somebin --opt13 --opt23
  run somebin --opt11 --opt22
  run otherbin --opt32 --opt42
  run otherbin --opt31 --opt41
  run otherbin --opt33 --opt43

  run steps_run "assert" "${mocks[@]}"
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

  mocks="$(steps_run "setup")"

  run bash -c "somebin --opt1 --opt2; somebin --opt1 --opt2; somebin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3"

  steps_run "assert" "${mocks[@]}"
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

  mocks="$(steps_run "setup")"

  run bash -c "somebin --opt1 --opt2; somebin --opt1 --opt2; somebin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3; otherbin --opt1 --opt2 --opt3"

  steps_run "assert" "${mocks[@]}"
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

  mocks="$(steps_run "setup")"
  run somebin --opt1 \
    --opt2 \
    --opt3 \
    "{" \
    "test": 1 \
    "}"
  steps_run "assert" "${mocks[@]}"
}

@test "Command with side effect - basic file creation" {
  declare -a STEPS=(
    '@somebin --opt1 # 0 # success # touch ${BATS_TEST_TMPDIR}/side_effect_file'
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/side_effect_file"
}

@test "Command with side effect - environment variable" {
  declare -a STEPS=(
    "@somebin --opt1 # 0 # success # export TEST_SIDE_EFFECT=executed"
  )

  mocks="$(steps_run "setup")"

  # Side effects are executed in the mock's context, not the test context
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Command with side effect - echo to file" {
  declare -a STEPS=(
    "@somebin --opt1 # 0 # success # echo 'side effect executed' > \${BATS_TEST_TMPDIR}/side_effect_output"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect output
  assert_file_exists "${BATS_TEST_TMPDIR}/side_effect_output"
  run cat "${BATS_TEST_TMPDIR}/side_effect_output"
  assert_output_contains "side effect executed"
}

@test "Command with side effect - multiple commands" {
  declare -a STEPS=(
    "@somebin --opt1 # 0 # success # touch \${BATS_TEST_TMPDIR}/file1; echo 'data' > \${BATS_TEST_TMPDIR}/file2"
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1
  assert_output_contains "success"
  assert_success

  steps_run "assert" "${mocks[@]}"

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

  mocks="$(steps_run "setup")"
  run somebin --opt1
  assert_output_contains "error message"
  assert_failure

  steps_run "assert" "${mocks[@]}"

  # Verify side effect was executed even with failure status
  assert_file_exists "${BATS_TEST_TMPDIR}/error_log"
  run cat "${BATS_TEST_TMPDIR}/error_log"
  assert_output_contains "error logged"
}

@test "Command with side effect - no output, only side effect" {
  declare -a STEPS=(
    '@somebin --opt1 # 0 # # touch ${BATS_TEST_TMPDIR}/no_output_side_effect'
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/no_output_side_effect"
}

@test "Command with side effect - shorthand status with side effect" {
  declare -a STEPS=(
    '@somebin --opt1 # success output # # touch ${BATS_TEST_TMPDIR}/shorthand_side_effect'
  )

  mocks="$(steps_run "setup")"
  run somebin --opt1
  assert_output_contains "success output"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/shorthand_side_effect"
}

@test "Multiple commands with different side effects" {
  declare -a STEPS=(
    '@cmd1 # 0 # output1 # touch ${BATS_TEST_TMPDIR}/cmd1_file'
    "@cmd2 # 0 # output2 # echo 'cmd2 executed' > \${BATS_TEST_TMPDIR}/cmd2_file"
  )

  mocks="$(steps_run "setup")"

  run cmd1
  assert_output_contains "output1"
  assert_success

  run cmd2
  assert_output_contains "output2"
  assert_success

  steps_run "assert" "${mocks[@]}"

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

  mocks="$(steps_run "setup")"

  run somebin
  assert_output_contains "call1"
  assert_success

  run somebin
  assert_output_contains "call2"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify both side effects were executed
  assert_file_exists "${BATS_TEST_TMPDIR}/call1_file"
  assert_file_exists "${BATS_TEST_TMPDIR}/call2_file"
}

@test "Command with side effect - error in parsing too many separators" {
  declare -a STEPS=(
    "@somebin # 0 # output # side effect # extra"
  )

  run steps_run "setup"
  assert_failure
  assert_output_contains "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
}

@test "Command with side effect - consecutive ## still forbidden" {
  declare -a STEPS=(
    "@somebin # 0 ## output # side effect"
  )

  run steps_run "setup"
  assert_failure
  assert_output_contains "ERROR: The string should not contain consecutive '##' and should have a maximum of three '#' characters in total."
}

@test "Wildcard command - any arguments accepted" {
  declare -a STEPS=(
    "@somebin * # 0 # wildcard output 1"
    "@somebin * # 0 # wildcard output 2"
    "@somebin * # 0 # wildcard output 3"
  )

  mocks="$(steps_run "setup")"

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

  steps_run "assert" "${mocks[@]}"
}

@test "Wildcard command - multiple calls with different args" {
  declare -a STEPS=(
    "@git * # 0 # git output 1"
    "@git * # 0 # git output 2"
  )

  mocks="$(steps_run "setup")"

  run git status
  assert_output_contains "git output 1"
  assert_success

  run git commit -m "test"
  assert_output_contains "git output 2"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Wildcard command - with side effects" {
  declare -a STEPS=(
    '@somebin * # 0 # wildcard success # touch ${BATS_TEST_TMPDIR}/wildcard_file'
  )

  mocks="$(steps_run "setup")"

  run somebin any args here
  assert_output_contains "wildcard success"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect was executed
  assert_file_exists "${BATS_TEST_TMPDIR}/wildcard_file"
}

@test "Wildcard command - error status" {
  declare -a STEPS=(
    "@somebin * # 1 # wildcard error"
  )

  mocks="$(steps_run "setup")"

  run somebin any args
  assert_output_contains "wildcard error"
  assert_failure

  steps_run "assert" "${mocks[@]}"
}

@test "Mixed exact and wildcard commands" {
  declare -a STEPS=(
    "@git status # 0 # exact status output"
    "@git * # 0 # wildcard git output"
    "@npm * # 1 # npm error"
  )

  mocks="$(steps_run "setup")"

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

  steps_run "assert" "${mocks[@]}"
}

@test "Wildcard command - shorthand syntax" {
  declare -a STEPS=(
    "@somebin * # wildcard shorthand output"
  )

  mocks="$(steps_run "setup")"

  run somebin any arguments
  assert_output_contains "wildcard shorthand output"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - URL with fragment in command arguments" {
  declare -a STEPS=(
    "@curl -fsSL https://example.com\#anchor -o file.php # 0"
  )

  mocks="$(steps_run "setup")"
  run curl -fsSL "https://example.com#anchor" -o file.php
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - Git URL with branch fragment" {
  declare -a STEPS=(
    "@git clone https://github.com/user/repo.git\#stable # 0 # Cloning repo"
  )

  mocks="$(steps_run "setup")"
  run git clone "https://github.com/user/repo.git#stable"
  assert_output_contains "Cloning repo"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - multiple escaped hashes in arguments" {
  declare -a STEPS=(
    "@somebin --url1=https://a.com\#tag1 --url2=https://b.com\#tag2 # 0"
  )

  mocks="$(steps_run "setup")"
  run somebin "--url1=https://a.com#tag1" "--url2=https://b.com#tag2"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - in output" {
  declare -a STEPS=(
    "@somebin # 0 # Output with \# hash"
  )

  mocks="$(steps_run "setup")"
  run somebin
  assert_output_contains "Output with # hash"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - in side effect" {
  declare -a STEPS=(
    '@somebin # 0 # success # echo "Comment \# starts here" > ${BATS_TEST_TMPDIR}/escaped_hash'
  )

  mocks="$(steps_run "setup")"
  run somebin
  assert_output_contains "success"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect contains unescaped hash
  assert_file_exists "${BATS_TEST_TMPDIR}/escaped_hash"
  run cat "${BATS_TEST_TMPDIR}/escaped_hash"
  assert_output_contains "Comment # starts here"
}

@test "Escaped hash - complex URL with query and fragment" {
  declare -a STEPS=(
    "@curl -fsSL https://example.com/install?key=123\#section -o installer.php # 0 # Downloaded"
  )

  mocks="$(steps_run "setup")"
  run curl -fsSL "https://example.com/install?key=123#section" -o installer.php
  assert_output_contains "Downloaded"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - mix of escaped and delimiter hashes" {
  declare -a STEPS=(
    "@php installer.php --uri=https://github.com/repo.git\#stable # 0 # Success \# done"
  )

  mocks="$(steps_run "setup")"
  run php installer.php "--uri=https://github.com/repo.git#stable"
  assert_output_contains "Success # done"
  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Escaped hash - all three parts with escaped hashes" {
  declare -a STEPS=(
    '@somebin --url=https://site.com\#tag # 0 # Message with \# hash # echo "Comment \# here" > ${BATS_TEST_TMPDIR}/all_escaped'
  )

  mocks="$(steps_run "setup")"
  run somebin "--url=https://site.com#tag"
  assert_output_contains "Message with # hash"
  assert_success

  steps_run "assert" "${mocks[@]}"

  # Verify side effect
  assert_file_exists "${BATS_TEST_TMPDIR}/all_escaped"
  run cat "${BATS_TEST_TMPDIR}/all_escaped"
  assert_output_contains "Comment # here"
}

@test "Escaped hash - real-world example from user" {
  declare -a STEPS=(
    "@curl -fsSL https://www.vortextemplate.com/install?1234567890 -o installer.php # 0"
    "@php installer.php --no-interaction --uri=https://github.com/drevops/vortex.git\#stable # 0"
    "Using installer script from URL: https://www.vortextemplate.com/install"
    "Downloading installer to installer.php"
  )

  mocks="$(steps_run "setup")"

  run bash -c "curl -fsSL https://www.vortextemplate.com/install?1234567890 -o installer.php && \
               php installer.php --no-interaction --uri=https://github.com/drevops/vortex.git#stable && \
               echo 'Using installer script from URL: https://www.vortextemplate.com/install' && \
               echo 'Downloading installer to installer.php'"

  assert_success

  steps_run "assert" "${mocks[@]}"
}

@test "Debug output" {
  debug="${BATS_TEST_TMPDIR}/debug.txt"
  export BATS_HELPERS_STEPS_DEBUG=1

  declare -a STEPS=(
    "@curl example.com # 0 # Some Substring"
    "Some Substring"
  )

  mocks="$(steps_run "setup" 3>"${debug}")"
  run curl example.com
  steps_run "assert" "${mocks[@]}" 3>>"${debug}"

  assert_file_contains "${debug}" "  > Phase       : setup"
  assert_file_contains "${debug}" "  > Phase       : assert"
  assert_file_contains "${debug}" "  > Total steps : 2"
  assert_file_contains "${debug}" "  > Type: command"
  assert_file_contains "${debug}" "  > Type: string present"
  assert_file_contains "${debug}" "  >   PARSE: STARTED"
  assert_file_contains "${debug}" "  >   PARSE: FINISHED"
}

@test "Debug output - disabled" {
  debug="${BATS_TEST_TMPDIR}/debug.txt"

  declare -a STEPS=(
    "Some Substring"
  )

  run echo "Some Substring"
  steps_run "assert" 3>"${debug}"

  assert_empty "$(cat "${debug}")"
}

@test "Missing STEPS" {
  run steps_run "assert"
  assert_failure
  assert_output_contains "STEPS array is empty."
}

@test "Missing STEPS - caller recovers" {
  recovered=0
  steps_run "assert" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Mocked command called fewer times than expected" {
  declare -a STEPS=(
    "@curl example.com # 0"
    "@curl example.org # 0"
  )

  mocks="$(steps_run "setup")"
  run curl example.com

  run steps_run "assert" "${mocks[@]}"
  assert_failure
  assert_output_contains "Mocked command 'curl' was expected to be called at least 2 time(s), but was called fewer times."
}

@test "Mocked command called fewer times than expected - caller recovers" {
  declare -a STEPS=(
    "@curl example.com # 0"
    "@curl example.org # 0"
  )

  mocks="$(steps_run "setup")"
  run curl example.com

  recovered=0
  steps_run "assert" "${mocks[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Expected call sequence" {
  declare -a STEPS=(
    "@git clone https://example.com/repo.git # 0"
    "@curl -s https://example.com/hook # 0"
    "@git checkout main # 0"
    "= git 'clone' 'https://example.com/repo.git'"
    "= curl '-s' 'https://example.com/hook'"
    "= git 'checkout' 'main'"
  )

  mocks="$(steps_run "setup")"
  "${BATS_TEST_DIRNAME}/fixtures/mock_interleaved.sh"
  steps_run "assert" "${mocks[@]}"
}

@test "Expected call sequence - out of order" {
  declare -a STEPS=(
    "@git clone https://example.com/repo.git # 0"
    "@curl -s https://example.com/hook # 0"
    "@git checkout main # 0"
    "= curl '-s' 'https://example.com/hook'"
    "= git 'clone' 'https://example.com/repo.git'"
    "= git 'checkout' 'main'"
  )

  mocks="$(steps_run "setup")"
  "${BATS_TEST_DIRNAME}/fixtures/mock_interleaved.sh"

  run steps_run "assert" "${mocks[@]}"
  assert_failure
  assert_output_contains "Call log does not match the expected sequence"
}

@test "Expected call sequence - caller recovers" {
  declare -a STEPS=(
    "@curl example.com # 0"
    "= curl 'example.org'"
  )

  mocks="$(steps_run "setup")"
  run curl example.com
  assert_success

  recovered=0
  steps_run "assert" "${mocks[@]}" 2>/dev/null || recovered=1

  assert_equal 1 "${recovered}"
}

@test "Mocked command called more times than expected" {
  declare -a STEPS=(
    "@curl example.com # 0"
  )

  mocks="$(steps_run "setup")"
  run curl example.com
  assert_success

  run curl example.org
  assert_failure
  assert_output_contains "Mock 'curl' received a call that no expectation covers: curl 'example.org'"

  run steps_run "assert" "${mocks[@]}"
  assert_failure
  assert_output_contains "Mock 'curl' received a call that no expectation covers: curl 'example.org'"
}

@test "Loading the library leaves the consumer shell options alone" {
  assert_string_not_contains "$-" "u"
}
