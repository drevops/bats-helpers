# Data provider

Run one function over many test cases (aka "data provider").

Source: [`src/dataprovider.bash`](../src/dataprovider.bash)

| Function                 | Description                                      | Arguments                                    |
|--------------------------|--------------------------------------------------|----------------------------------------------|
| `dataprovider_run`       | Runs the cases held in the `TEST_CASES` array    | `func_name`, `[args_per_row]`, `[assertion]` |
| `dataprovider_run_cases` | Runs the cases that a function declares          | `func_name`, `cases_func`, `[assertion]`     |
| `dataprovider_case`      | Declares and runs one case                       | `label`, `[arg...]`, `expected`              |
| `dataprovider_matrix`    | Expands value lists into their cartesian product | `case_func`, `list_name...`                  |

| Variable     | Read by            | Description                                                                                        |
|--------------|--------------------|----------------------------------------------------------------------------------------------------|
| `TEST_CASES` | `dataprovider_run` | Array of test cases, each row ending with its expected value. Declared with `declare -a` above the call |

There are three forms. Reach for the **flat array** when every case has the same shape and reads well as a table. Reach for **declared cases** when a case needs a name, when arity differs between cases, or when a value is empty or holds spaces, tabs or newlines. Reach for the **matrix** when the cases are every combination of two or more value lists.

Every form runs the function under test with `run` and then applies an assertion to the case's expected value, so any single-argument assertion in this library is a valid choice: `assert_output`, `assert_output_matches`, `assert_status`, `assert_output_not_contains`, and so on. The default is `assert_output_contains`.

## Flat array

`TEST_CASES` holds every case end to end, `args_per_row` says how wide a row is, and the last column of each row is the expected value:

```bash
# Function to test.
add_numbers() {
  echo "$(($1 + $2))"
}

@test "Test add_numbers" {
  # Numbers: first two are inputs, last is expected output.
  declare -a TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "add_numbers" 3
}
```

A failure names the rows that broke by their zero-based index:

```text
Failed sets (0-based): 1, 3
Total failed test sets: 2
```

An expected value must not be empty here, because in a fixed-width table an empty last column is how a short row shows up. Use declared cases for a case whose expected value is genuinely empty.

Pass an assertion as the third argument to check something other than containment:

```bash
declare -a TEST_CASES=(
  1 2 3
)
dataprovider_run "add_numbers" 3 "assert_output"
```

## Declared cases

A function declares one case per `dataprovider_case` call. Each call states its own arity, and the values never leave the argument list, so empty values and values holding spaces, tabs or newlines need no quoting:

```bash
# Function to test.
count_args() {
  echo "count=$#"
}

provide_cases() {
  dataprovider_case "no arguments" "count=0"
  dataprovider_case "one argument" "a" "count=1"
  dataprovider_case "an empty argument" "" "count=1"
  # An empty label reports the case by its index instead.
  dataprovider_case "" "a" "b" "count=2"
}

@test "Test count_args" {
  dataprovider_run_cases "count_args" "provide_cases"
}
```

The label is what a failure names, so nothing has to be counted to find the case that broke:

```text
Error: Failed for set 'an empty argument'

Failed sets: 'an empty argument'
Total failed test sets: 1
```

## Matrix

`dataprovider_matrix` expands value lists into their cartesian product and hands each combination to a function, which turns it into a case. That is where the label and the expected value are derived from the combination rather than repeated for it:

```bash
# Function to test.
describe_match() {
  echo "${1}:${2}"
}

emit_case() {
  dataprovider_case "${1}, case ${2}" "${1}" "${2}" "${1}:${2}"
}

provide_cases() {
  dataprovider_matrix "emit_case" modes flags
}

@test "Test describe_match" {
  declare -a modes=("literal" "regex" "format")
  declare -a flags=(0 1)

  dataprovider_run_cases "describe_match" "provide_cases"
}
```

That runs six cases in the order `literal 0`, `literal 1`, `regex 0`, `regex 1`, `format 0`, `format 1` - the last list varies fastest, so they arrive in the order a written-out table would list them.

Lists are passed by name rather than by value, because separating them inside one argument list would need a separator and any separator is also a value a list is entitled to hold. A list that is empty is an error rather than an empty product, since a provider that expands to nothing runs nothing and would otherwise pass.
