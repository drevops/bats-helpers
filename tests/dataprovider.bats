#!/usr/bin/env bats
#
# Tests for the data provider runner.
#
# shellcheck disable=SC2034

load _test_helper

add_numbers() {
  local num1="${1}"
  local num2="${2}"
  echo $((num1 + num2))
}

concat_values() {
  local num1="${1}"
  local num2="${2}"
  echo "${num1}${num2}"
}

describe_args() {
  echo "count=$#"
  local arg
  for arg in "$@"; do
    echo "arg=[${arg}]"
  done
}

provide_cases() {
  dataprovider_case "adds two positives" 1 2 3
  dataprovider_case "adds a negative" 5 -2 3
}

provide_failing_cases() {
  dataprovider_case "adds two positives" 1 2 3
  dataprovider_case "adds a negative" 5 -2 33
  dataprovider_case "adds zero" 0 0 1
}

provide_unlabelled_cases() {
  dataprovider_case "" 1 2 33
}

provide_mixed_labels() {
  dataprovider_case "" 1 2 33
  dataprovider_case "named" 1 2 33
}

provide_varying_arity() {
  dataprovider_case "no arguments" "count=0"
  dataprovider_case "one argument" "a" "count=1"
  dataprovider_case "two arguments" "a" "b" "count=2"
}

provide_empty_values() {
  dataprovider_case "empty value" "" $'count=1\narg=[]'
  dataprovider_case "empty among values" "" "x" "" $'count=3\narg=[]\narg=[x]\narg=[]'
}

provide_space_values() {
  dataprovider_case "spaces" "a b  c" $'count=1\narg=[a b  c]'
}

provide_tab_values() {
  dataprovider_case "tabs" $'a\tb' $'count=1\narg=[a\tb]'
}

provide_newline_values() {
  dataprovider_case "newlines" $'a\nb' $'count=1\narg=[a\nb]'
}

provide_regex_cases() {
  dataprovider_case "sums to a number" 1 2 "^[0-9]+$"
}

provide_no_cases() {
  return 0
}

provide_case_without_expected() {
  dataprovider_case "no expected value"
}

matrix_emit_pair() {
  matrix_seen+=("${1}|${2}")
  dataprovider_case "${1}-${2}" "${1}" "${2}" "${1}${2}"
}

matrix_emit_single() {
  matrix_seen+=("${1}")
  dataprovider_case "${1}" "${1}" "${1}" "${1}${1}"
}

matrix_emit_triple() {
  matrix_seen+=("${1}${2}${3}")
  dataprovider_case "" "${1}" "${2}" "${3}" "count=3"
}

provide_matrix_pairs() {
  dataprovider_matrix "matrix_emit_pair" matrix_first matrix_second
}

provide_matrix_singles() {
  dataprovider_matrix "matrix_emit_single" matrix_first
}

provide_matrix_triples() {
  dataprovider_matrix "matrix_emit_triple" matrix_first matrix_second matrix_third
}

@test "dataprovider_run called directly" {
  # Numbers.
  declare -a TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "add_numbers" 3

  # String.
  declare -a TEST_CASES=(
    "start" "finish" "startfinish"
  )
  dataprovider_run "concat_values" 3

  # More arguments than needed is allowed.
  declare -a TEST_CASES=(
    "start" "middle" "finish" "startmiddle"
  )
  dataprovider_run "concat_values" 4

  # An omitted assertion and an empty one both mean "not given", so both take
  # the default.
  declare -a TEST_CASES=(
    1 2 3
  )
  dataprovider_run "add_numbers" 3 ""
}

@test "dataprovider_run" {
  declare -a TEST_CASES=(
    1 2 3
    1 2 3
  )

  run dataprovider_run "add_numbers" 3
  assert_success

  assert_output_not_contains "Failed sets (0-based)"
  assert_output_not_contains "Total failed test sets"
}

@test "dataprovider_run with failing cases" {
  declare -a TEST_CASES=(
    1 2 3
    1 2 4
    1 2 3
    1 2 4
  )

  run dataprovider_run "add_numbers" 3
  assert_failure
  assert_output_contains "Failed sets (0-based): 1, 3"
  assert_output_contains "Total failed test sets: 2"
}

@test "dataprovider_run with invalid input" {
  run dataprovider_run "" 3
  assert_failure
  assert_output_contains "Function name must not be empty."

  run dataprovider_run "non_existing_func" 3
  assert_failure
  assert_output_contains "Function 'non_existing_func' is not a valid function."

  run dataprovider_run "add_numbers" 3 "non_existing_func"
  assert_failure
  assert_output_contains "Assertion 'non_existing_func' is not a valid function."

  run dataprovider_run "add_numbers" "three"
  assert_failure
  assert_output_contains "Number of arguments per test case 'three' is not an integer."

  run dataprovider_run "add_numbers" 0
  assert_failure
  assert_output_contains "Number of arguments per test case must be greater than zero."

  run dataprovider_run "add_numbers" 2
  assert_failure
  assert_output_contains "TEST_CASES array is empty."

  declare -a TEST_CASES=()
  run dataprovider_run "add_numbers" 2
  assert_failure
  assert_output_contains "TEST_CASES array is empty."

  declare -a TEST_CASES=(
    1 2
  )
  run dataprovider_run "add_numbers" 3
  assert_failure
  assert_output_contains "Number of arguments per test case is greater than the total elements in TEST_CASES."

  declare -a TEST_CASES=(
    1 2 3
    1 2
  )
  run dataprovider_run "add_numbers" 3
  assert_failure
  assert_output_contains "Total elements in TEST_CASES must be a multiple of '3'."

  declare -a TEST_CASES=(
    1 2 3
    1 2 ""
    1 2 4
  )
  run dataprovider_run "add_numbers" 3
  assert_failure
  assert_output_contains "Expected value (last element) in the data set '1' is empty."
}

@test "dataprovider_run with a custom assertion" {
  declare -a TEST_CASES=(
    1 2 3
    4 5 9
  )

  dataprovider_run "add_numbers" 3 "assert_output"
}

@test "dataprovider_run with a custom assertion that fails" {
  declare -a TEST_CASES=(
    1 23 23
  )

  # The same data passes containment and fails an exact comparison, so only the
  # assertion tells the two runs apart.
  dataprovider_run "concat_values" 3

  run dataprovider_run "concat_values" 3 "assert_output"
  assert_failure
  assert_output_contains "Failed sets (0-based): 0"
  assert_output_contains "Total failed test sets: 1"
}

@test "dataprovider_run_cases called directly" {
  dataprovider_run_cases "add_numbers" "provide_cases"
}

@test "dataprovider_run_cases" {
  run dataprovider_run_cases "add_numbers" "provide_cases"
  assert_success

  assert_output_not_contains "Failed sets"
  assert_output_not_contains "Total failed test sets"
}

@test "dataprovider_run_cases with failing cases" {
  run dataprovider_run_cases "add_numbers" "provide_failing_cases"
  assert_failure
  assert_output_contains "Error: Failed for set 'adds a negative'"
  assert_output_contains "Error: Failed for set 'adds zero'"
  assert_output_contains "Failed sets: 'adds a negative', 'adds zero'"
  assert_output_contains "Total failed test sets: 2"
  assert_output_not_contains "0-based"
}

@test "dataprovider_run_cases without a label" {
  run dataprovider_run_cases "add_numbers" "provide_unlabelled_cases"
  assert_failure
  assert_output_contains "Error: Failed for set 0"
  assert_output_contains "Failed sets (0-based): 0"
  assert_output_contains "Total failed test sets: 1"
}

@test "dataprovider_run_cases with mixed labels" {
  run dataprovider_run_cases "add_numbers" "provide_mixed_labels"
  assert_failure
  assert_output_contains "Error: Failed for set 0"
  assert_output_contains "Error: Failed for set 'named'"
  assert_output_contains "Failed sets: 0, 'named'"
  assert_output_contains "Total failed test sets: 2"
}

@test "dataprovider_run_cases with varying arity" {
  dataprovider_run_cases "describe_args" "provide_varying_arity"
}

@test "dataprovider_run_cases with empty values" {
  dataprovider_run_cases "describe_args" "provide_empty_values" "assert_output"
}

@test "dataprovider_run_cases with spaces" {
  dataprovider_run_cases "describe_args" "provide_space_values" "assert_output"
}

@test "dataprovider_run_cases with tabs" {
  dataprovider_run_cases "describe_args" "provide_tab_values" "assert_output"
}

@test "dataprovider_run_cases with newlines" {
  dataprovider_run_cases "describe_args" "provide_newline_values" "assert_output"
}

@test "dataprovider_run_cases with a custom assertion" {
  dataprovider_run_cases "add_numbers" "provide_regex_cases" "assert_output_matches"
}

@test "dataprovider_run_cases with a custom assertion that fails" {
  run dataprovider_run_cases "add_numbers" "provide_regex_cases" "assert_output_not_matches"
  assert_failure
  assert_output_contains "Failed sets: 'sums to a number'"
}

@test "dataprovider_run_cases with invalid input" {
  run dataprovider_run_cases "" "provide_cases"
  assert_failure
  assert_output_contains "Function name must not be empty."

  run dataprovider_run_cases "non_existing_func" "provide_cases"
  assert_failure
  assert_output_contains "Function 'non_existing_func' is not a valid function."

  run dataprovider_run_cases "add_numbers" ""
  assert_failure
  assert_output_contains "Cases function name must not be empty."

  run dataprovider_run_cases "add_numbers" "non_existing_func"
  assert_failure
  assert_output_contains "Cases function 'non_existing_func' is not a valid function."

  # An omitted assertion and an empty one both mean "not given", so both take
  # the default.
  dataprovider_run_cases "add_numbers" "provide_cases" ""

  run dataprovider_run_cases "add_numbers" "provide_cases" "non_existing_func"
  assert_failure
  assert_output_contains "Assertion 'non_existing_func' is not a valid function."

  run dataprovider_run_cases "add_numbers" "provide_no_cases"
  assert_failure
  assert_output_contains "Cases function 'provide_no_cases' declared no test cases."

  run dataprovider_run_cases "add_numbers" "provide_case_without_expected"
  assert_failure
  assert_output_contains "A test case requires a label and an expected value."
  assert_output_contains "Cases function 'provide_case_without_expected' exited with a non-zero status."
}

@test "dataprovider_case outside a runner" {
  run dataprovider_case "label" "expected"
  assert_failure
  assert_output_contains "Function 'dataprovider_case' must be called from the function passed to 'dataprovider_run_cases'."
}

@test "dataprovider_matrix" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1" "2" "3")
  declare -a matrix_seen=()

  dataprovider_run_cases "concat_values" "provide_matrix_pairs"

  assert_equal "6" "${#matrix_seen[@]}"
  assert_equal "a|1 a|2 a|3 b|1 b|2 b|3" "${matrix_seen[*]}"
}

@test "dataprovider_matrix with a single list" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_seen=()

  dataprovider_run_cases "concat_values" "provide_matrix_singles"

  assert_equal "2" "${#matrix_seen[@]}"
  assert_equal "a b" "${matrix_seen[*]}"
}

@test "dataprovider_matrix with a list holding one value" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1")
  declare -a matrix_seen=()

  dataprovider_run_cases "concat_values" "provide_matrix_pairs"

  assert_equal "2" "${#matrix_seen[@]}"
  assert_equal "a|1 b|1" "${matrix_seen[*]}"
}

@test "dataprovider_matrix with three lists" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1" "2")
  declare -a matrix_third=("x" "y")
  declare -a matrix_seen=()

  dataprovider_run_cases "describe_args" "provide_matrix_triples"

  assert_equal "8" "${#matrix_seen[@]}"
  assert_equal "a1x a1y a2x a2y b1x b1y b2x b2y" "${matrix_seen[*]}"
}

@test "dataprovider_matrix with failing cases" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1" "2")
  declare -a matrix_seen=()

  run dataprovider_run_cases "concat_values" "provide_matrix_pairs" "assert_output_not_contains"
  assert_failure
  assert_output_contains "Failed sets: 'a-1', 'a-2', 'b-1', 'b-2'"
  assert_output_contains "Total failed test sets: 4"
}

@test "dataprovider_matrix with invalid input" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_empty=()
  declare matrix_scalar="a"

  run dataprovider_matrix "" matrix_first
  assert_failure
  assert_output_contains "Case function name must not be empty."

  run dataprovider_matrix "non_existing_func" matrix_first
  assert_failure
  assert_output_contains "Case function 'non_existing_func' is not a valid function."

  run dataprovider_matrix "matrix_emit_pair"
  assert_failure
  assert_output_contains "At least one value list is required."

  run dataprovider_matrix "matrix_emit_pair" "not an identifier"
  assert_failure
  assert_output_contains "Value list name 'not an identifier' is not a valid variable name."

  run dataprovider_matrix "matrix_emit_pair" matrix_missing
  assert_failure
  assert_output_contains "Value list 'matrix_missing' is not declared."

  run dataprovider_matrix "matrix_emit_pair" matrix_scalar
  assert_failure
  assert_output_contains "Value list 'matrix_scalar' is not an indexed array."

  run dataprovider_matrix "matrix_emit_pair" matrix_empty
  assert_failure
  assert_output_contains "Value list 'matrix_empty' is empty."
}
