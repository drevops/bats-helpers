#!/usr/bin/env bash
##
# @file
# Data provider to run a function over multiple test cases.
#

##
# Runs multiple test cases for a given function (aka data provider).
#
# An expected value must not be empty: in a fixed-width table an empty last
# column is how a short row shows up. Use 'dataprovider_run_cases' for a case
# whose expected value is genuinely empty.
#
# Arguments:
#   1. func_name: Name of the function to be tested.
#   2. args_per_row: Number of elements in each row of the TEST_CASES array,
#      counting the trailing expected value. Optional, defaults to 1. The
#      function under test receives one argument fewer.
#   3. assertion: Assertion to apply to each case, called with the case's
#      expected value once the output has been captured. Optional, defaults to
#      'assert_output_contains'.
#
# Globals:
#   TEST_CASES: Array of test cases, each row ending with its expected value.
#
# Examples:
#   Two inputs and one expected value per row:
#     declare -a TEST_CASES=(1 2 3)
#     dataprovider_run "add_numbers" 3
##
dataprovider_run() {
  local func_name="${1-}"
  local args_per_row="${2:-1}"
  local assertion="${3:-assert_output_contains}"

  ##
  ## Input validation.
  ##

  dataprovider_validate_function "${func_name}" "Function" || return 1
  dataprovider_validate_function "${assertion}" "Assertion" || return 1

  if ! [[ ${args_per_row} =~ ^-?[0-9]+$ ]]; then
    flunk "Number of arguments per test case '${args_per_row}' is not an integer."
    return 1
  fi

  # Using the normal run() function is sufficient for testing functions with no
  # arguments.
  if [ "${args_per_row}" -le 0 ]; then
    flunk "Number of arguments per test case must be greater than zero."
    return 1
  fi

  if [ -z "${TEST_CASES+x}" ]; then
    flunk "TEST_CASES array is empty."
    return 1
  fi

  if [ "${args_per_row}" -gt "${#TEST_CASES[@]}" ]; then
    flunk "Number of arguments per test case is greater than the total elements in TEST_CASES."
    return 1
  fi

  if [ "$((${#TEST_CASES[@]} % args_per_row))" -ne 0 ]; then
    flunk "Total elements in TEST_CASES must be a multiple of '${args_per_row}'."
    return 1
  fi

  local i
  local data_set_idx
  for ((i = args_per_row - 1, data_set_idx = 0; i < ${#TEST_CASES[@]}; i += args_per_row, data_set_idx++)); do
    if [ -z "${TEST_CASES[i]}" ]; then
      flunk "Expected value (last element) in the data set '${data_set_idx}' is empty."
      return 1
    fi
  done

  ##
  ## Runner.
  ##

  # 'dataprovider_case' reads the run's state from this frame through dynamic
  # scoping, which is why the state is declared here and not in a shared helper.
  local BATS_HELPERS_DATAPROVIDER_FUNC="${func_name}"
  local BATS_HELPERS_DATAPROVIDER_ASSERT="${assertion}"
  local BATS_HELPERS_DATAPROVIDER_INDEX=0
  local BATS_HELPERS_DATAPROVIDER_LABELLED=0
  local -a BATS_HELPERS_DATAPROVIDER_FAILED=()

  for ((i = 0; i < ${#TEST_CASES[@]}; i += args_per_row)); do
    dataprovider_case "" "${TEST_CASES[@]:i:args_per_row}"
  done

  dataprovider_report
}

##
## Declared cases.
##

##
# Runs the test cases that a function declares.
#
# Arguments:
#   1. func_name: Name of the function to be tested.
#   2. cases_func: Name of the function declaring the cases. It is called once
#      and calls 'dataprovider_case' for each case.
#   3. assertion: Assertion to apply to each case, called with the case's
#      expected value once the output has been captured. Optional, defaults to
#      'assert_output_contains'.
#
# Examples:
#   provide_cases() {
#     dataprovider_case "adds two positives" 1 2 3
#     dataprovider_case "adds a negative" 5 -2 3
#   }
#   dataprovider_run_cases "add_numbers" "provide_cases"
##
dataprovider_run_cases() {
  local func_name="${1-}"
  local cases_func="${2-}"
  local assertion="${3:-assert_output_contains}"

  dataprovider_validate_function "${func_name}" "Function" || return 1
  dataprovider_validate_function "${cases_func}" "Cases function" || return 1
  dataprovider_validate_function "${assertion}" "Assertion" || return 1

  # 'dataprovider_case' reads the run's state from this frame through dynamic
  # scoping, which is why the state is declared here and not in a shared helper.
  local BATS_HELPERS_DATAPROVIDER_FUNC="${func_name}"
  local BATS_HELPERS_DATAPROVIDER_ASSERT="${assertion}"
  local BATS_HELPERS_DATAPROVIDER_INDEX=0
  local BATS_HELPERS_DATAPROVIDER_LABELLED=0
  local -a BATS_HELPERS_DATAPROVIDER_FAILED=()

  if ! "${cases_func}"; then
    flunk "Cases function '${cases_func}' exited with a non-zero status."
    return 1
  fi

  # A provider that declares nothing runs nothing and would otherwise pass.
  if [ "${BATS_HELPERS_DATAPROVIDER_INDEX}" -eq 0 ]; then
    flunk "Cases function '${cases_func}' declared no test cases."
    return 1
  fi

  dataprovider_report
}

##
# Declares one test case and runs it.
#
# The case runs where it is declared so that its values never leave the argument
# list: an empty value, or one holding spaces, tabs or newlines, survives
# without quoting. Arity is stated per call, so it may differ between cases.
#
# Arguments:
#   1. label: Name to report the case by. Pass an empty string to report it by
#      its index instead.
#   2. args: Arguments to pass to the function under test. Optional.
#   3. expected: Expected value to pass to the assertion, always last.
#
# Globals:
#   BATS_HELPERS_DATAPROVIDER_FUNC: Function under test.
#   BATS_HELPERS_DATAPROVIDER_ASSERT: Assertion to apply.
#   BATS_HELPERS_DATAPROVIDER_INDEX: Index of the next case, advanced here.
#   BATS_HELPERS_DATAPROVIDER_LABELLED: Set to 1 once a case carries a label.
#   BATS_HELPERS_DATAPROVIDER_FAILED: Failed cases, appended to here.
#
# Outputs:
#   STDOUT: A line naming the case, when it fails.
#
# Returns:
#   Zero for a case that fails its assertion, so that the remaining cases still
#   run; non-zero only when the call itself is malformed.
##
dataprovider_case() {
  if [ -z "${BATS_HELPERS_DATAPROVIDER_FUNC+x}" ]; then
    flunk "Function 'dataprovider_case' must be called from the function passed to 'dataprovider_run_cases'."
    return 1
  fi

  if [ "$#" -lt 2 ]; then
    flunk "A test case requires a label and an expected value."
    return 1
  fi

  local label="${1}"
  shift

  local expected="${*: -1}"
  local -a args=("${@:1:$#-1}")

  local description="${BATS_HELPERS_DATAPROVIDER_INDEX}"

  if [ -n "${label}" ]; then
    description="'${label}'"
    BATS_HELPERS_DATAPROVIDER_LABELLED=1
  fi

  BATS_HELPERS_DATAPROVIDER_INDEX=$((BATS_HELPERS_DATAPROVIDER_INDEX + 1))

  run "${BATS_HELPERS_DATAPROVIDER_FUNC}" "${args[@]}"

  if "${BATS_HELPERS_DATAPROVIDER_ASSERT}" "${expected}"; then
    return 0
  fi

  echo "Error: Failed for set ${description}"
  BATS_HELPERS_DATAPROVIDER_FAILED+=("${description}")
}

##
## Matrix expansion.
##

##
# Expands value lists into their cartesian product.
#
# Each combination is handed to a function that turns it into a test case, which
# is what lets the label and the expected value be derived from the combination
# rather than repeated for it. Combinations are emitted in row-major order, so
# the last list varies fastest and they arrive in the order a written-out table
# would list them.
#
# Lists are named rather than passed by value because separating them inside one
# argument list needs a separator, and any separator is also a value a list is
# entitled to hold.
#
# Arguments:
#   1. case_func: Function called once per combination, with the combination as
#      its arguments.
#   2. list_names: Names of the indexed arrays to expand. At least one.
#
# Examples:
#   declare -a modes=("literal" "regex")
#   declare -a flags=(0 1)
#   dataprovider_matrix "emit_case" modes flags
##
dataprovider_matrix() {
  local case_func="${1-}"

  dataprovider_validate_function "${case_func}" "Case function" || return 1

  if [ "$#" -lt 2 ]; then
    flunk "At least one value list is required."
    return 1
  fi

  shift

  ##
  ## List resolution.
  ##

  local -a values=()
  local -a counts=()
  local name
  local ref
  local -a list

  for name in "$@"; do
    if ! [[ ${name} =~ ^[A-Za-z_][A-Za-z_0-9]*$ ]]; then
      flunk "Value list name '${name}' is not a valid variable name."
      return 1
    fi

    if ! declare -p "${name}" >/dev/null 2>&1; then
      flunk "Value list '${name}' is not declared."
      return 1
    fi

    if [[ $(declare -p "${name}") != "declare -a"* ]]; then
      flunk "Value list '${name}' is not an indexed array."
      return 1
    fi

    ref="${name}[@]"
    list=("${!ref}")

    # An empty list makes the product empty, which would run no cases at all and
    # report nothing.
    if [ "${#list[@]}" -eq 0 ]; then
      flunk "Value list '${name}' is empty."
      return 1
    fi

    counts+=("${#list[@]}")
    values+=("${list[@]}")
  done

  ##
  ## Product walk.
  ##

  local list_count="$#"
  local -a cursor=()
  local i

  for ((i = 0; i < list_count; i++)); do
    cursor[i]=0
  done

  local -a combination
  local offset
  local position

  while true; do
    combination=()
    offset=0

    for ((i = 0; i < list_count; i++)); do
      combination+=("${values[offset + cursor[i]]}")
      offset=$((offset + counts[i]))
    done

    "${case_func}" "${combination[@]}" || return 1

    for ((position = list_count - 1; position >= 0; position--)); do
      cursor[position]=$((cursor[position] + 1))

      if [ "${cursor[position]}" -lt "${counts[position]}" ]; then
        break
      fi

      cursor[position]=0
    done

    if [ "${position}" -lt 0 ]; then
      break
    fi
  done
}

##
## Validation and reporting.
##

##
# Validates that a name given to the provider is a function.
#
# Arguments:
#   1. name: Name to validate.
#   2. noun: Capitalised role of the name, used to open both messages.
##
dataprovider_validate_function() {
  local name="${1}"
  local noun="${2}"

  if [ -z "${name}" ]; then
    flunk "${noun} name must not be empty."
    return 1
  fi

  if [ "$(type -t "${name}")" != "function" ]; then
    flunk "${noun} '${name}' is not a valid function."
    return 1
  fi
}

##
# Reports the cases that failed.
#
# Globals:
#   BATS_HELPERS_DATAPROVIDER_LABELLED: '1' when at least one case carried a
#     label, which is what makes the indices in the summary meaningless.
#   BATS_HELPERS_DATAPROVIDER_FAILED: Failed cases.
#
# Outputs:
#   STDOUT: The failed cases, when there are any.
##
dataprovider_report() {
  if [ "${#BATS_HELPERS_DATAPROVIDER_FAILED[@]}" -eq 0 ]; then
    return 0
  fi

  local summary=""
  local description

  for description in "${BATS_HELPERS_DATAPROVIDER_FAILED[@]}"; do
    summary="${summary}${description}, "
  done

  summary="${summary%, }"

  echo

  if [ "${BATS_HELPERS_DATAPROVIDER_LABELLED}" = "1" ]; then
    echo "Failed sets: ${summary}"
  else
    echo "Failed sets (0-based): ${summary}"
  fi

  flunk "Total failed test sets: ${#BATS_HELPERS_DATAPROVIDER_FAILED[@]}"
}
