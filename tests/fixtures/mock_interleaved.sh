#!/usr/bin/env bash
# Fixture script to test the ordered call log.
# LCOV_EXCL_START
set -e

git clone https://example.com/repo.git

curl -s https://example.com/hook

git checkout main
# LCOV_EXCL_STOP
