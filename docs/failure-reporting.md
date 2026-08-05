# Failure reporting

How every helper in the library reports a failure, and the two functions that do the reporting.

Source: [`src/assert.base.bash`](../src/assert.base.bash)

| Function Name  | Description                                                    |
|----------------|----------------------------------------------------------------|
| `flunk`        | Fails the test with a message, its stack trace and stable paths |
| `format_error` | Formats a failure report as a titled block of aligned rows      |

Helpers report a failure by writing a message to STDERR and returning a non-zero status. None of them call `exit`, so the caller stays in control and can compose them with `||`, branch on them with `if`, or capture the status with `run`:

```bash
# Recover from a failure and carry on.
fixture_export_codebase "${build_dir}" \
  || echo "Export failed - continuing without a codebase."

# Capture the status and the message.
run tui_run "${answers[@]}"
assert_failure
assert_output_contains "SCRIPT_FILE is not set."
```

A bare call still fails the test at that point, because BATS runs tests with `errexit` enabled.

## The report

Every assertion reports through one path, so a failure always reads the same way: a banner marking where the failure starts and ends, a title naming what went wrong, then the values that decided it as aligned rows. A run prints the output of the code under test alongside the library's own, so the banner is what makes the failure findable in it. It closes below the stack trace rather than above it, so nothing belonging to the failure falls outside the two markers.

```text
##################################################
#             BEGIN ERROR MESSAGE                #
##################################################
-- String does not contain substring --
string     : some text
substring  : SOME
match mode : literal
case       : sensitive
note       : it matches without the '_case' suffix
--

-- stack trace --
${PWD}/tests/example.bats:12: assert_string_contains_case
--
##################################################
#              END ERROR MESSAGE                 #
##################################################
```

The examples below show the block on its own, without the surrounding banner.

## Multi-line values

When any value spans lines, every row switches to a labelled form carrying its line count. They switch together, so two values stay comparable rather than one collapsing onto a single line and the other not:

```text
-- Line does not contain substring --
line (1 line):
1
substring (1 line):
absent
match mode (1 line):
literal
case (1 line):
insensitive
context (4 lines):
  0: Usage: tool.sh
> 1: Reading config
  2: Deleted 12 files
  3: Done.
--
```

## Diffs

A mismatch between an expected and an actual value is rendered as a unified diff rather than as two blobs:

```text
-- Strings are not equal --
--- expected
+++ actual
@@ -1,3 +1,3 @@
 first
-second
+changed
 third
--
```

The diff is coloured when the platform's `diff` understands `--color`. Set `NO_COLOR` to any non-empty value to suppress it, or `BATS_HELPERS_REPORT_COLOR` to decide either way:

```bash
export BATS_HELPERS_REPORT_COLOR=0
```

## Stack traces and stable paths

The stack trace names the file, line and function of each of your own frames, leaving out the library's own and bats-core's, so a failure raised several calls deep inside a helper points at the helper and not only at the test. Paths that change between runs - the bats-core temporary directories, the working directory and the home directory - are rewritten to the names of the variables holding them, so the same failure is the same text on every machine and in every run.
