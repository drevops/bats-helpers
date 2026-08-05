# Documentation

Each page below documents one module of the library and names it in a `Source:` line. [Match modes](match-modes.md) is the one exception: it describes what every assertion family shares, so no single module owns it. The [API reference](../README.md#-api-reference) in the project README lists every public function with the source file that defines it and a link into the page that documents it.

A variable is documented on the page of the feature that reads it, beside the behaviour it changes, rather than in a reference list of its own.

Deprecated functions, variables and arguments are not documented here. They live in [`MIGRATION.md`](../MIGRATION.md) alone, so these pages describe only the surface a new test should be written against.

## Assertions

| Page                                             | Source                                                     | Covers                                                            |
|--------------------------------------------------|------------------------------------------------------------|-------------------------------------------------------------------|
| [Command assertions](assertions-command.md)      | [`src/assert.command.bash`](../src/assert.command.bash)    | Output, exit statuses and standard error of a command run with `run` |
| [Line assertions](assertions-line.md)            | [`src/assert.line.bash`](../src/assert.line.bash)          | Individual lines of a captured stream, by index, by any line and by count |
| [String assertions](assertions-string.md)        | [`src/assert.string.bash`](../src/assert.string.bash)      | Plain strings, and the string utilities behind the assertions      |
| [File assertions](assertions-file.md)            | [`src/assert.file.bash`](../src/assert.file.bash)          | Files, directories and symbolic links                              |
| [Git assertions](assertions-git.md)              | [`src/assert.git.bash`](../src/assert.git.bash)            | Git repositories and the files they track                          |
| [Match modes](match-modes.md)                    | [`src/assert.string.bash`](../src/assert.string.bash)      | How a needle is read, and whether case matters                     |
| [Failure reporting](failure-reporting.md)        | [`src/assert.base.bash`](../src/assert.base.bash)          | The shape of every failure report, and how to raise one            |

## Test utilities

| Page                                       | Source                                                 | Covers                                                        |
|--------------------------------------------|--------------------------------------------------------|---------------------------------------------------------------|
| [Mocking](mocking.md)                      | [`src/mock.bash`](../src/mock.bash)                    | Command mocking, the call log, argument specifications, strictness and sandbox mode |
| [Step runner](steps.md)                    | [`src/steps.bash`](../src/steps.bash)                  | Sequences of mocked calls and output assertions               |
| [Data provider](dataprovider.md)           | [`src/dataprovider.bash`](../src/dataprovider.bash)    | Running one function over many test cases                     |
| [Interactive scripts](tui.md)              | [`src/tui.bash`](../src/tui.bash)                      | Driving a script that asks questions                          |
| [Retry](retry.md)                          | [`src/retry.bash`](../src/retry.bash)                  | Conditions that become true shortly                           |
| [Cleanup](cleanup.md)                      | [`src/cleanup.bash`](../src/cleanup.bash)              | Deferred per-test cleanup                                     |
| [Fixtures](fixtures.md)                    | [`src/fixture.bash`](../src/fixture.bash)              | Building, dumping and asserting file trees                    |
| [File utilities](files.md)                 | [`src/file.bash`](../src/file.bash)                    | Creating, trimming, backing up and restoring files            |

## Naming

Everything the library provides carries the `BATS_HELPERS_` prefix, because `load.bash` is sourced into your test shell and an unprefixed global would collide silently with your own. The prefix covers what the library provides, not what it consumes, so the variables it reads from elsewhere keep their own names: bats-core's `BATS_TEST_TMPDIR`, `BATS_TMPDIR`, `BATS_TEST_DIRNAME` and `BATS_VERBOSE_RUN` are documented by [bats-core](https://bats-core.readthedocs.io/), and `NO_COLOR` follows [the convention](https://no-color.org/) - any non-empty value suppresses the colour of a diff in a failure report.

`STEPS`, `TEST_CASES` and `SCRIPT_FILE` are the three exceptions and stay unprefixed. They are not configuration but the test data itself, declared on the lines directly above the call that reads them, so the declaration and its use are read together.

## Public API

The functions these pages document are the public API. Functions whose names start with an underscore - `_mock_log_quote`, `_report_diff` - are internal, are not part of the public API, and are exempt from the deprecation policy: they may change or disappear in any release without notice.
