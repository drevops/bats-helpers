#!/usr/bin/env bash
##
# @file
# Data provider to run a function over multiple test cases.
#

##
# Runs multiple test cases for a given function (aka data provider).
#
# Arguments:
#   1. func_name: Name of the function to be tested.
#   2. args_per_row: Number of elements in each row of the
#      BATS_HELPERS_TEST_CASES array, counting the trailing expected value.
#      Optional, defaults to 1. The function under test receives one argument
#      fewer.
#
# Globals:
#   BATS_HELPERS_TEST_CASES: Array of test cases, each row ending with its
#     expected value.
#
# Examples:
#   Two inputs and one expected value per row:
#     declare -a BATS_HELPERS_TEST_CASES=(1 2 3)
#     dataprovider_run "add_numbers" 3
##
dataprovider_run() {
  local func_name="${1}"
  local args_per_row="${2:-1}"

  ##
  ## Input validation.
  ##

  if [ -z "${func_name}" ]; then
    flunk "Function name must not be empty."
    return
  fi

  if ! type -t "${func_name}" | grep -q 'function'; then
    flunk "Function '${func_name}' is not a valid function."
    return
  fi

  # Using the normal run() function is sufficient for testing functions with no
  # arguments.
  if [ "${args_per_row}" -le 0 ]; then
    flunk "Number of arguments per test case must be greater than zero."
    return
  fi

  local -a test_cases=()
  if [ -n "${BATS_HELPERS_TEST_CASES+x}" ]; then
    test_cases=("${BATS_HELPERS_TEST_CASES[@]}")
  elif [ -n "${TEST_CASES+x}" ]; then
    [ -n "${BATS_HELPERS_DEPRECATION_QUIET-}" ] || echo "Deprecated: 'TEST_CASES' will be removed in the next version. Use 'BATS_HELPERS_TEST_CASES' instead." >&3
    test_cases=("${TEST_CASES[@]}")
  else
    flunk "BATS_HELPERS_TEST_CASES array is empty."
    return
  fi

  if [ "${args_per_row}" -gt ${#test_cases[@]} ]; then
    flunk "Number of arguments per test case is greater than the total elements in BATS_HELPERS_TEST_CASES."
    return
  fi

  if [ "$((${#test_cases[@]} % args_per_row))" -ne 0 ]; then
    flunk "Total elements in BATS_HELPERS_TEST_CASES must be a multiple of ${args_per_row}."
    return
  fi

  local i
  local data_set_idx
  for ((i = args_per_row - 1, data_set_idx = 0; i < ${#test_cases[@]}; i += args_per_row, data_set_idx++)); do
    if [ -z "${test_cases[i]}" ]; then
      flunk "Expected value (last element) in the data set ${data_set_idx} is empty."
      return
    fi
  done

  ##
  ## Runner.
  ##

  local set_idx=0
  local error_count=0
  local failed_sets=""
  local expected
  local test_args

  for ((i = 0; i < ${#test_cases[@]}; i += args_per_row)); do
    expected="${test_cases[i + args_per_row - 1]}"
    test_args=("${test_cases[@]:i:args_per_row-1}")

    run "${func_name}" "${test_args[@]}"

    if ! assert_output_contains "${expected}"; then
      echo "Error: Failed for set ${set_idx}"
      error_count=$((error_count + 1))
      failed_sets="${failed_sets}${set_idx}, "
    fi

    set_idx=$((set_idx + 1))
  done

  ##
  ## Error reporting.
  ##

  if [ "${error_count}" -ne 0 ]; then
    failed_sets=${failed_sets%, } # Remove the trailing comma.
    echo
    echo "Failed sets (0-based): ${failed_sets}"
    flunk "Total failed test sets: ${error_count}"
  fi
}
