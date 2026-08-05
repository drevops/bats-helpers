# Git assertions

Assertions for git repositories and the files they track.

Source: [`src/assert.git.bash`](../src/assert.git.bash)

| Function Name                 | Description                                      |
|-------------------------------|--------------------------------------------------|
| `assert_git_repo`             | Asserts that a directory is a git repository     |
| `assert_git_not_repo`         | Asserts that a directory is not a git repository |
| `assert_git_clean`            | Asserts that a git repository is clean           |
| `assert_git_not_clean`        | Asserts that a git repository is not clean       |
| `assert_git_file_tracked`     | Asserts that a file is tracked in git            |
| `assert_git_file_not_tracked` | Asserts that a file is not tracked in git        |

`assert_git_file_tracked` and `assert_git_file_not_tracked` report through the exit status alone and print no message.

These assertions run `git`, so they need it allowed when the [mock sandbox](mocking.md#sandbox-mode) is enabled.
