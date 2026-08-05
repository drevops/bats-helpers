# Documentation

Each page below documents one module of the library. The [API reference](../README.md#-api-reference) in the project README lists every public function with the source file that defines it and a link into the page that documents it.

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

## Reference

| Page                                                | Covers                                              |
|-----------------------------------------------------|-----------------------------------------------------|
| [Environment variables](environment-variables.md)   | Every variable the library reads or writes          |
| [Deprecations](deprecations.md)                     | Renamed functions, variables and arguments          |

## Public API

The functions these pages document are the public API. Functions whose names start with an underscore - `_mock_log_quote`, `_report_diff` - are internal, are not part of the public API, and are exempt from the deprecation policy: they may change or disappear in any release without notice.
