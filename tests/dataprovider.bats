#!/usr/bin/env bats
#
# Tests for the data provider runner.
#
# shellcheck disable=SC2034

load _test_helper

fixture_add() {
  local num1="${1}"
  local num2="${2}"
  echo $((num1 + num2))
}

fixture_concat() {
  local num1="${1}"
  local num2="${2}"
  echo "${num1}${num2}"
}

fixture_args() {
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

matrix_emit_triple() {
  matrix_seen+=("${1}${2}${3}")
  dataprovider_case "" "${1}" "${2}" "${3}" "count=3"
}

provide_matrix_pairs() {
  dataprovider_matrix "matrix_emit_pair" matrix_first matrix_second
}

provide_matrix_triples() {
  dataprovider_matrix "matrix_emit_triple" matrix_first matrix_second matrix_third
}

@test "Test dataprovider runner, direct - success" {
  # Numbers.
  declare -a TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "fixture_add" 3

  # String.
  declare -a TEST_CASES=(
    "start" "finish" "startfinish"
  )
  dataprovider_run "fixture_concat" 3

  # More arguments than needed is allowed.
  declare -a TEST_CASES=(
    "start" "middle" "finish" "startmiddle"
  )
  dataprovider_run "fixture_concat" 4
}

@test "Test dataprovider runner - success" {
  declare -a TEST_CASES=(
    1 2 3
    1 2 3
  )

  run dataprovider_run "fixture_add" 3
  assert_success

  assert_output_not_contains "Failed sets (0-based)"
  assert_output_not_contains "Total failed test sets"
}

@test "Test dataprovider runner - failure" {
  declare -a TEST_CASES=(
    1 2 3
    1 2 4
    1 2 3
    1 2 4
  )

  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Failed sets (0-based): 1, 3"
  assert_output_contains "Total failed test sets: 2"
}

@test "Test dataprovider runner, validation - failure" {
  run dataprovider_run "" 3
  assert_failure
  assert_output_contains "Function name must not be empty."

  run dataprovider_run "non_existing_func" 3
  assert_failure
  assert_output_contains "Function 'non_existing_func' is not a valid function."

  run dataprovider_run "fixture_add" 3 ""
  assert_failure
  assert_output_contains "Assertion name must not be empty."

  run dataprovider_run "fixture_add" 3 "non_existing_func"
  assert_failure
  assert_output_contains "Assertion 'non_existing_func' is not a valid function."

  run dataprovider_run "fixture_add" "three"
  assert_failure
  assert_output_contains "Number of arguments per test case 'three' is not an integer."

  run dataprovider_run "fixture_add" 0
  assert_failure
  assert_output_contains "Number of arguments per test case must be greater than zero."

  run dataprovider_run "fixture_add" 2
  assert_failure
  assert_output_contains "TEST_CASES array is empty."

  declare -a TEST_CASES=()
  run dataprovider_run "fixture_add" 2
  assert_failure
  assert_output_contains "TEST_CASES array is empty."

  declare -a TEST_CASES=(
    1 2
  )
  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Number of arguments per test case is greater than the total elements in TEST_CASES."

  declare -a TEST_CASES=(
    1 2 3
    1 2
  )
  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Total elements in TEST_CASES must be a multiple of 3."

  declare -a TEST_CASES=(
    1 2 3
    1 2 ""
    1 2 4
  )
  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Expected value (last element) in the data set 1 is empty."
}

@test "Test dataprovider runner, custom assertion - success" {
  declare -a TEST_CASES=(
    1 2 3
    4 5 9
  )

  dataprovider_run "fixture_add" 3 "assert_output"
}

@test "Test dataprovider runner, custom assertion - failure" {
  declare -a TEST_CASES=(
    1 23 23
  )

  # The same data passes containment and fails an exact comparison, so only the
  # assertion tells the two runs apart.
  dataprovider_run "fixture_concat" 3

  run dataprovider_run "fixture_concat" 3 "assert_output"
  assert_failure
  assert_output_contains "Failed sets (0-based): 0"
  assert_output_contains "Total failed test sets: 1"
}

@test "Test dataprovider runner, declared cases, direct - success" {
  dataprovider_run_cases "fixture_add" "provide_cases"
}

@test "Test dataprovider runner, declared cases - success" {
  run dataprovider_run_cases "fixture_add" "provide_cases"
  assert_success

  assert_output_not_contains "Failed sets"
  assert_output_not_contains "Total failed test sets"
}

@test "Test dataprovider runner, declared cases - failure" {
  run dataprovider_run_cases "fixture_add" "provide_failing_cases"
  assert_failure
  assert_output_contains "Error: Failed for set 'adds a negative'"
  assert_output_contains "Error: Failed for set 'adds zero'"
  assert_output_contains "Failed sets: 'adds a negative', 'adds zero'"
  assert_output_contains "Total failed test sets: 2"
  assert_output_not_contains "0-based"
}

@test "Test dataprovider runner, declared cases without a label - failure" {
  run dataprovider_run_cases "fixture_add" "provide_unlabelled_cases"
  assert_failure
  assert_output_contains "Error: Failed for set 0"
  assert_output_contains "Failed sets (0-based): 0"
  assert_output_contains "Total failed test sets: 1"
}

@test "Test dataprovider runner, declared cases with mixed labels - failure" {
  run dataprovider_run_cases "fixture_add" "provide_mixed_labels"
  assert_failure
  assert_output_contains "Error: Failed for set 0"
  assert_output_contains "Error: Failed for set 'named'"
  assert_output_contains "Failed sets: 0, 'named'"
  assert_output_contains "Total failed test sets: 2"
}

@test "Test dataprovider runner, declared cases with varying arity - success" {
  dataprovider_run_cases "fixture_args" "provide_varying_arity"
}

@test "Test dataprovider runner, declared cases with empty values - success" {
  dataprovider_run_cases "fixture_args" "provide_empty_values" "assert_output"
}

@test "Test dataprovider runner, declared cases with spaces - success" {
  dataprovider_run_cases "fixture_args" "provide_space_values" "assert_output"
}

@test "Test dataprovider runner, declared cases with tabs - success" {
  dataprovider_run_cases "fixture_args" "provide_tab_values" "assert_output"
}

@test "Test dataprovider runner, declared cases with newlines - success" {
  dataprovider_run_cases "fixture_args" "provide_newline_values" "assert_output"
}

@test "Test dataprovider runner, declared cases with a custom assertion - success" {
  dataprovider_run_cases "fixture_add" "provide_regex_cases" "assert_output_matches"
}

@test "Test dataprovider runner, declared cases with a custom assertion - failure" {
  run dataprovider_run_cases "fixture_add" "provide_regex_cases" "assert_output_not_matches"
  assert_failure
  assert_output_contains "Failed sets: 'sums to a number'"
}

@test "Test dataprovider runner, declared cases validation - failure" {
  run dataprovider_run_cases "" "provide_cases"
  assert_failure
  assert_output_contains "Function name must not be empty."

  run dataprovider_run_cases "non_existing_func" "provide_cases"
  assert_failure
  assert_output_contains "Function 'non_existing_func' is not a valid function."

  run dataprovider_run_cases "fixture_add" ""
  assert_failure
  assert_output_contains "Cases function name must not be empty."

  run dataprovider_run_cases "fixture_add" "non_existing_func"
  assert_failure
  assert_output_contains "Cases function 'non_existing_func' is not a valid function."

  run dataprovider_run_cases "fixture_add" "provide_cases" ""
  assert_failure
  assert_output_contains "Assertion name must not be empty."

  run dataprovider_run_cases "fixture_add" "provide_cases" "non_existing_func"
  assert_failure
  assert_output_contains "Assertion 'non_existing_func' is not a valid function."

  run dataprovider_run_cases "fixture_add" "provide_no_cases"
  assert_failure
  assert_output_contains "Cases function 'provide_no_cases' declared no test cases."

  run dataprovider_run_cases "fixture_add" "provide_case_without_expected"
  assert_failure
  assert_output_contains "A test case requires a label and an expected value."
  assert_output_contains "Cases function 'provide_case_without_expected' exited with a non-zero status."
}

@test "Test dataprovider case, outside a runner - failure" {
  run dataprovider_case "label" "expected"
  assert_failure
  assert_output_contains "Function 'dataprovider_case' must be called from the function passed to 'dataprovider_run_cases'."
}

@test "Test dataprovider matrix - success" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1" "2" "3")
  declare -a matrix_seen=()

  dataprovider_run_cases "fixture_concat" "provide_matrix_pairs"

  assert_equal "6" "${#matrix_seen[@]}"
  assert_equal "a|1 a|2 a|3 b|1 b|2 b|3" "${matrix_seen[*]}"
}

@test "Test dataprovider matrix, single list - success" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1")
  declare -a matrix_seen=()

  dataprovider_run_cases "fixture_concat" "provide_matrix_pairs"

  assert_equal "2" "${#matrix_seen[@]}"
  assert_equal "a|1 b|1" "${matrix_seen[*]}"
}

@test "Test dataprovider matrix, three lists - success" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1" "2")
  declare -a matrix_third=("x" "y")
  declare -a matrix_seen=()

  dataprovider_run_cases "fixture_args" "provide_matrix_triples"

  assert_equal "8" "${#matrix_seen[@]}"
  assert_equal "a1x a1y a2x a2y b1x b1y b2x b2y" "${matrix_seen[*]}"
}

@test "Test dataprovider matrix - failure" {
  declare -a matrix_first=("a" "b")
  declare -a matrix_second=("1" "2")
  declare -a matrix_seen=()

  run dataprovider_run_cases "fixture_concat" "provide_matrix_pairs" "assert_output_not_contains"
  assert_failure
  assert_output_contains "Failed sets: 'a-1', 'a-2', 'b-1', 'b-2'"
  assert_output_contains "Total failed test sets: 4"
}

@test "Test dataprovider matrix, validation - failure" {
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
