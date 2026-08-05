# String assertions

Assertions and utilities for plain strings.

Source: [`src/assert.string.bash`](../src/assert.string.bash)

## Assertions

| Function Name                   | Description                                               |
|---------------------------------|-----------------------------------------------------------|
| `assert_empty`                  | Asserts that a string is empty                            |
| `assert_not_empty`              | Asserts that a string is not empty                        |
| `assert_equal`                  | Asserts that two strings are equal                        |
| `assert_string_contains`        | Asserts that a string contains a given substring          |
| `assert_string_not_contains`    | Asserts that a string does not contain a substring        |
| `assert_string_starts_with`     | Asserts that a string starts with a substring             |
| `assert_string_not_starts_with` | Asserts that a string does not start with a substring     |
| `assert_string_ends_with`       | Asserts that a string ends with a substring               |
| `assert_string_not_ends_with`   | Asserts that a string does not end with a substring       |
| `assert_string_matches`         | Asserts that a string matches a regular expression        |
| `assert_string_not_matches`     | Asserts that a string does not match a regular expression |
| `assert_string_matches_format`     | Asserts that a string matches a format string          |
| `assert_string_not_matches_format` | Asserts that a string does not match a format string   |

Every assertion below `assert_equal` has a `_case` twin that matches case-sensitively - `assert_string_contains_case`, `assert_string_not_starts_with_case` and so on. `assert_empty`, `assert_not_empty` and `assert_equal` compare exactly and have no twin. See [Match modes](match-modes.md).

Every `contains` assertion takes the container first and the string to look for second:

```bash
assert_string_contains "some needle in a haystack" "needle"
assert_file_contains "${file}" "needle"
assert_dir_contains_string "${dir}" "needle"
```

## String utilities

| Function Name            | Description                                                          |
|--------------------------|----------------------------------------------------------------------|
| `string_random`          | Generates a random alphanumeric string, 8 characters long by default |
| `string_match`           | Reports whether a needle matches a haystack, without asserting on it |
| `string_format_to_regex` | Translates a format string into an extended regular expression       |

Use `string_match` to make the same comparison an assertion makes without asserting on it, and `string_format_to_regex` to see what a format string expands to. Both take plain values rather than any of the assertion names:

```bash
# Haystack, needle, mode, case sensitivity, anchor.
string_match "Deleted 12 files" "deleted" "literal" 0 "start"

# Prints 'Deleted [0-9]+ files'.
string_format_to_regex "Deleted %d files"
```

`string_match` returns `0` when the needle matches, `1` when it does not, and `2` when the needle is not a usable regular expression. It reports through the exit status alone and prints nothing.
