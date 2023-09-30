---
title: Data provider
layout: default
nav_order: 3
---

# Data provider

Run multiple test cases for a given function (aka Data Provider).

Arguments:
  1. `func_name`: The name of the function to be tested.
  2. `args_per_row`: (Optional) The number of arguments in each row of the
     `TEST_CASES` array, defaults to 1. Last argument is always the expected
      value.

Global Variables:
  `TEST_CASES`: An array containing test cases with their expected values.

Examples:
  To run a function `test_func` with `TEST_CASES` containing two arguments per row,
  you can call run_test_cases like so:
    `run_test_cases "test_func" 2`

```bash
# Function to test.
add_numbers() {
  echo "$(($1 + $2))"
}

@test "Test add_numbers" {
  # Numbers.
  TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "add_numbers" 3
}
```
