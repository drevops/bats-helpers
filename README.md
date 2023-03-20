# BATS helpers
Helpers and assertions for [BATS](https://github.com/bats-core/bats-core) testing.

[![Tests](https://github.com/drevops/bats-helpers/actions/workflows/tests.yml/badge.svg)](https://github.com/drevops/bats-helpers/actions/workflows/tests.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/drevops/bats-helpers)
![LICENSE](https://img.shields.io/github/license/drevops/bats-helpers)

## Assertions

- `assert_binary_files_equal`
- `assert_binary_files_not_equal`
- `assert_contains`
- `assert_dir_contains_string`
- `assert_dir_empty`
- `assert_dir_exists`
- `assert_dir_not_contains_string`
- `assert_dir_not_empty`
- `assert_dir_not_exists`
- `assert_dirs_equal`
- `assert_empty`
- `assert_equal`
- `assert_failure`
- `assert_file_contains`
- `assert_file_exists`
- `assert_file_mode`
- `assert_file_not_contains`
- `assert_file_not_exists`
- `assert_files_equal`
- `assert_files_not_equal`
- `assert_git_clean`
- `assert_git_file_is_not_tracked`
- `assert_git_file_is_tracked`
- `assert_git_not_clean`
- `assert_git_repo`
- `assert_not_contains`
- `assert_not_empty`
- `assert_not_git_repo`
- `assert_output`
- `assert_output_contains`
- `assert_output_not_contains`
- `assert_success`
- `assert_symlink_exists`
- `assert_symlink_not_exists`

## Helpers

- `add_var_to_file`
- `debug`
- `format_error`
- `mktouch`
- `prepare_fixture_dir`
- `random_string`
- `restore_file`
- `trim_file`

## Installation and usage

1. Install as NPM package.

   ```bash
   npm install -D bats-helpers@npm:@drevops/bats-helpers
   ```

2. Create a `_loader.bash` file next to your BATS tests with content:

   ```bash
   export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/../node_modules"
   bats_load_library bats-helpers
   ```

3. Use `load _loader.bash` in every BATS file:

   ```bash
   #!/usr/bin/env bats
   load _loader

   @test "My test" {
     run ls
     asser_success
   }
   ```

## Maintenance

    npm install

    npm run lint

    npm run test

## Why not `bats-assert`, `bats-file`, `bats-support`

The goal is to merge is to eventually merge this package with [bats-assert](https://github.com/bats-core/bats-assert).

However:
1. This package has more assertions and tests. They were battle-tested on many
   projects and were waiting for BATS to provide support for libraries
   functionality to be extracted into a standalone package.
2. Those packages have outdated version constraints which leads to conflicts.
