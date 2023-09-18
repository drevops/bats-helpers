<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=BATS%20helpers&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="Project logo"></a>
</p>

<h1 align="center">BATS helpers</h1>

<div align="center">

[![GitHub Issues](https://img.shields.io/github/issues/drevops/bats-helpers.svg)](https://github.com/drevops/bats-helpers/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/drevops/bats-helpers.svg)](https://github.com/drevops/bats-helpers/pulls)
[![Test](https://github.com/drevops/bats-helpers/actions/workflows/test.yml/badge.svg)](https://github.com/drevops/bats-helpers/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/drevops/bats-helpers/graph/badge.svg?token=O0ZYROWCCK)](https://codecov.io/gh/drevops/bats-helpers)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/drevops/bats-helpers)
![LICENSE](https://img.shields.io/github/license/drevops/bats-helpers)
</div>

---

<p align="center"> Helpers and assertions for <a href="https://github.com/bats-core/bats-core">BATS</a> testing.
    <br>
   <a href="https://bats-helpers.drevops.com">Documentation</a>
</p>

## Features

- [Assertions](docs/assertions.md)
- [Mocking](docs/mocking.md)
- [Helpers](docs/helpers.md)

## Installation

```bash
npm install -D bats-helpers@npm:@drevops/bats-helpers
```

## Usage

1. Create a `_loader.bash` file next to your BATS tests with content:

   ```bash
   export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/../node_modules"
   bats_load_library bats-helpers
   ```

2. Use `load _loader.bash` in every BATS file:

   ```bash
   #!/usr/bin/env bats
   load _loader

   @test "My test" {
     run ls
     assert_success
   }
   ```

## Why not `bats-assert`, `bats-file`, `bats-support`

The goal is to merge is to eventually merge this package with [bats-assert](https://github.com/bats-core/bats-assert).

However:
1. This package has more assertions and tests. They were battle-tested on many
   projects and were waiting for BATS to provide support for libraries
   functionality to be extracted into a standalone package.
2. Those packages have outdated version constraints which leads to conflicts.


## Acknowledgments

The mocking functionality is based on
the [bats-mock](https://github.com/grayhemp/bats-mock) project.
A special thank you to the contributors for their original work.

## Maintenance

    npm install

    npm run lint

    npm run test

### Publishing

    npm version minor

    git push

    npm publish
