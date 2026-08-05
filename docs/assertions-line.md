# Line assertions

`run` also splits what it captured into `${lines[@]}`. These assert against a line rather than against the output as a whole, which is what a command-line tool's output is usually shaped like.

Source: [`src/assert.line.bash`](../src/assert.line.bash)

## By index

Assert a line by index. A negative index counts back from the end, so `-1` is the last line:

| Function Name                    | Description                                                        |
|----------------------------------|--------------------------------------------------------------------|
| `assert_line`                    | Asserts that the line at an index equals a string                  |
| `assert_line_not`                | Asserts that the line at an index does not equal a string          |
| `assert_line_contains`           | Asserts that the line at an index contains a string                |
| `assert_line_not_contains`       | Asserts that the line at an index does not contain a string        |
| `assert_line_matches`            | Asserts that the line at an index matches a regular expression     |
| `assert_line_not_matches`        | Asserts that the line at an index does not match a regular expression |
| `assert_line_matches_format`     | Asserts that the line at an index matches a format string          |
| `assert_line_not_matches_format` | Asserts that the line at an index does not match a format string   |

## Any line

Assert that some line matches, without pinning which one. The positive reads `any`, the negative reads `no`:

| Function Name                       | Description                                            |
|-------------------------------------|--------------------------------------------------------|
| `assert_any_line`                   | Asserts that some line equals a string                 |
| `assert_no_line`                    | Asserts that no line equals a string                   |
| `assert_any_line_contains`          | Asserts that some line contains a string               |
| `assert_no_line_contains`           | Asserts that no line contains a string                 |
| `assert_any_line_matches`           | Asserts that some line matches a regular expression    |
| `assert_no_line_matches`            | Asserts that no line matches a regular expression      |
| `assert_any_line_matches_format`    | Asserts that some line matches a format string         |
| `assert_no_line_matches_format`     | Asserts that no line matches a format string           |

## Counts

Assert how many lines there are, or how many of them a needle matches:

| Function Name                        | Description                                                |
|--------------------------------------|------------------------------------------------------------|
| `assert_line_count`                  | Asserts the number of lines                                |
| `assert_line_count_not`              | Asserts that the number of lines differs                   |
| `assert_line_count_contains`         | Asserts how many lines contain a string                    |
| `assert_line_count_not_contains`     | Asserts how many lines do not contain a string             |
| `assert_line_count_matches`          | Asserts how many lines match a regular expression          |
| `assert_line_count_not_matches`      | Asserts how many lines do not match a regular expression   |
| `assert_line_count_matches_format`   | Asserts how many lines match a format string               |
| `assert_line_count_not_matches_format` | Asserts how many lines do not match a format string      |

Every `contains`, `matches` and `matches_format` assertion above has a `_case` twin that matches case-sensitively - `assert_line_contains_case`, `assert_no_line_matches_case`, `assert_line_count_not_contains_case` and so on. `assert_line`, `assert_line_not`, `assert_any_line`, `assert_no_line` and the two `assert_line_count` assertions compare exactly and have no twin. See [Match modes](match-modes.md).

## Negation

`not` negates whatever follows it. Where a verb follows, it negates the match, exactly as it does elsewhere in the library: `assert_line_count_not_contains 3 "error"` asserts that three lines do **not** contain `error`, not that the number of lines containing it is other than three. Where nothing follows it - `assert_line_not`, `assert_line_count_not` - there is no verb to negate, so it negates the assertion's own comparison:

```bash
run ./script.sh

assert_line 0 "Usage: script.sh [options]"
assert_line -1 "Done."
assert_line_contains 2 "config"
assert_any_line_matches 'Deleted [0-9]+ files'
assert_no_line_contains "Warning"
assert_line_count 4
assert_line_count_contains 2 "error"
```

## Failures

An index outside the captured lines is an error naming both the index and the number of lines, rather than a comparison against an empty string that would read as an ordinary mismatch:

```text
Line index '5' is out of range for output with 2 lines.
```

A failure shows the offending line in context rather than the whole stream. The mark overwrites the indent instead of being inserted, so the lines stay in the same column:

```text
-- Line does not contain substring --
line (1 line):
2
substring (1 line):
error
match mode (1 line):
literal
case (1 line):
insensitive
context (4 lines):
  0: Usage: tool.sh
  1: Reading config
> 2: all good
  3: Done.
--
```

## Empty lines and indices

`run` drops empty lines unless it is asked to keep them, so an empty line is not an element of `${lines[@]}` and every index after it shifts up. Pass `--keep-empty-lines` when the blank lines are part of what is being asserted, or when an index has to line up with the output as it was printed:

```bash
bats_require_minimum_version 1.13.0

# 'lines' holds 'first' and 'third'; the empty line is not an element.
run printf '%s\n' "first" "" "third"
assert_line_count 2
assert_line 1 "third"

# 'lines' holds all three, and the indices match the printed output.
run --keep-empty-lines printf '%s\n' "first" "" "third"
assert_line_count 3
assert_line 1 ""
assert_line 2 "third"
```

As with `--separate-stderr`, that declaration has to be `1.5.0` or newer, or bats-core prints a `BW02` warning for every `run` that carries a flag.
