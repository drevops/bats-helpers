# Contributing

Thank you for considering a contribution to BATS helpers.

## Reporting an issue

Search the [existing issues](https://github.com/drevops/bats-helpers/issues) before opening a new one. A report is most useful when it names the BATS version and the operating system, and includes a minimal test that reproduces the behaviour.

## Local setup

Requires [Node.js](https://nodejs.org). `bats-core` is installed alongside the other dependencies:

```shell
npm install
```

Linting additionally requires [shellcheck](https://www.shellcheck.net) and [shfmt](https://github.com/mvdan/sh).

## Running the tests

```shell
npm run test
```

Pass any other flag, or a single file, to `bats` directly:

```shell
./node_modules/.bin/bats tests/assert.base.bats
./node_modules/.bin/bats --verbose-run tests/
./node_modules/.bin/bats --timing tests/
```

`--verbose-run` prints each test's `BATS_TEST_TMPDIR`, which is where the fixtures for that test are built.

Coverage is measured with [kcov](https://github.com/SimonKagstrom/kcov) in CI and uploaded to [Codecov](https://codecov.io/gh/drevops/bats-helpers). CI runs the suite on Ubuntu and macOS, against both the current and the lowest supported `bats-core`.

## Linting

```shell
npm run lint
```

`npm run lint-fix` applies the `shfmt` formatting in place. It does not fix `shellcheck` findings.

## Coding standards

[`CLAUDE.md`](CLAUDE.md) holds the conventions this library is written to: how helpers are named, how failure messages are worded, and how file headers and function docblocks are laid out. Read it before adding a helper.

Two rules that are easy to miss:

- A helper is named `<subject>_<verb>` after the module that owns it, because Bash has no namespaces and the prefix is the namespace. The `assert_*` family is the exception and keeps the verb first.
- Every assertion is tested for both its positive and its negative behaviour, in one `@test` per assertion.

## Releasing

```shell
npm version minor
git push --follow-tags
npm publish
```

`npm version` creates an annotated tag that a plain `git push` leaves behind, so `--follow-tags` is what gets the tag to GitHub.

The `Draft release notes` workflow runs on pushes to `main` and on tag pushes, and assembles the GitHub release draft from the merged pull request titles.
