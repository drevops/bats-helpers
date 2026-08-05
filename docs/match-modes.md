# Match modes

How a needle is read, and whether case matters, is chosen by picking the assertion - there are no options to pass. Every combination has a name, so a call site says what it compares without being read against a flag elsewhere in the file.

The modes below apply to every assertion family. The matching engine behind them is in [`src/assert.string.bash`](../src/assert.string.bash).

Three things vary. **How the needle is read** is the verb:

| Verb             | The needle is                             |
|------------------|-------------------------------------------|
| `contains`       | A literal substring                       |
| `starts_with`    | A literal prefix                          |
| `ends_with`      | A literal suffix                          |
| `matches`        | An extended regular expression            |
| `matches_format` | A format string, see below                |

**Whether it must be present** is the `not_` prefix, and **whether case matters** is the `_case` suffix. Absent the suffix, the match ignores case, which is what the library has always done:

```bash
assert_output_contains            "Deleted 12 files"    # ignores case
assert_output_contains_case       "Deleted 12 files"    # case-sensitive
assert_output_not_contains        "Removed"
assert_output_not_contains_case   "removed"

assert_output_matches             'Deleted [0-9]+ files'
assert_output_matches_case        'Deleted [0-9]+ files'
assert_output_matches_format      "Deleted %d files"

assert_string_starts_with_case    "${line}" "WARNING"
assert_file_not_matches_case      "${log}" 'FATAL'
```

The same twelve names exist for each of `string`, `output`, `stderr` and `file`, and the four prefix and suffix forms for `string`. A needle is only ever a needle, so one that looks like an option needs no escaping:

```bash
assert_output_contains "usage: --verbose enables logging"
```

## Format strings

**Prefer a literal assertion.** A literal needle cannot be broken by a character that happens to be a regular expression operator, and its failure report can be read straight against the value it did not match. Reach for `matches` only for the part of a value that genuinely varies between runs - a timestamp, a PID, a duration, a version - and leave the rest literal. Where the only variation is a number or a word, `matches_format` says so without a regular expression:

| Placeholder | Matches                                   |
|-------------|-------------------------------------------|
| `%d`        | A run of digits                           |
| `%f`        | A number with an optional fractional part |
| `%s`        | A run of non-whitespace characters        |
| `%%`        | A literal `%`                             |

Everything outside a placeholder is matched literally, so a format string escapes nothing of its own:

```bash
assert_output_matches_format "Deleted %d files in %fs"
assert_file_matches_format "${log}" "user %s logged in"
```

## Anchoring

The prefix and suffix assertions, and the `^` and `$` anchors of a regular expression, all apply to the whole value rather than to each of its lines:

```bash
# The whole output is 'Done', not merely one of its lines.
assert_output_matches '^Done$'
```

## Failures

A needle that is not a usable regular expression is reported as an error rather than as a mismatch, so a `not_matches` assertion fails on it too:

```text
Invalid regular expression '['.
```

The failure report names the mode and the case sensitivity that were in force, and calls out the case sensitivity when the other choice would have decided the assertion the other way:

```text
-- String does not contain substring --
string     : some text
substring  : SOME
match mode : literal
case       : sensitive
note       : it matches without the '_case' suffix
--
```

## Matching without asserting

`string_match` makes the same comparison without asserting on it, and `string_format_to_regex` expands a format string. See [String utilities](assertions-string.md#string-utilities).
