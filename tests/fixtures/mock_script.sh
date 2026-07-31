#!/usr/bin/env bash
# Fixture script to test mocking.
# LCOV_EXCL_START
set -e

curl -L -s -o /dev/null -w "%{http_code}" example.com

curl example.com
