#!/usr/bin/env bash
# Fixture script to test that a deadline reaches what a TUI script started.
# LCOV_EXCL_START
set -e

# The worker outlives the deadline unless the whole process group is signalled.
sleep 30 &

echo "$!" >"${WORKER_PID_FILE}"

echo "Static script output"

# Never answered, so the deadline is what ends this script.
while true; do
  sleep 0.1
done
# LCOV_EXCL_STOP
