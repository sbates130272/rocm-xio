#!/bin/bash
# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# CTest wrapper for xio-tester test-ep emulation cases. These cases are
# CPU-only because --emulate skips HIP runtime initialization.

set -euo pipefail

XIO_TESTER="${XIO_TESTER:-./build/xio-tester}"
CASE="${1:-smoke}"

if [ ! -x "$XIO_TESTER" ]; then
  echo "SKIP: xio-tester not found at $XIO_TESTER"
  exit 77
fi

require_output() {
  local output="$1"
  local needle="$2"

  if [[ "$output" != *"$needle"* ]]; then
    echo "FAIL: expected output to contain: $needle"
    echo "--- command output ---"
    echo "$output"
    echo "----------------------"
    exit 1
  fi
}

require_verify_counts() {
  local output="$1"
  local passed="$2"
  local failed="$3"

  if [[ ! "$output" =~ Verify[[:space:]]Passed:[[:space:]]+$passed ]]; then
    echo "FAIL: expected Verify Passed to be $passed"
    echo "$output"
    exit 1
  fi
  if [[ ! "$output" =~ Verify[[:space:]]Failed:[[:space:]]+$failed ]]; then
    echo "FAIL: expected Verify Failed to be $failed"
    echo "$output"
    exit 1
  fi
}

run_success() {
  local output

  if ! output="$("$XIO_TESTER" test-ep --emulate "$@" 2>&1)"; then
    echo "$output"
    exit 1
  fi

  require_output "$output" "Test completed successfully!"
  echo "$output"
}

run_failure() {
  local expected="$1"
  shift
  local output

  if output="$("$XIO_TESTER" test-ep --emulate "$@" 2>&1); then
    echo "FAIL: expected command to fail"
    echo "$output"
    exit 1
  fi

  require_output "$output" "$expected"
  echo "$output"
}

case "$CASE" in
  smoke)
    run_success --iterations 8 --threads 1 --less-timing
    ;;
  verify)
    output="$(run_success --iterations 8 --threads 1 --less-timing \
      --verify --seed 4660)"
    require_verify_counts "$output" 8 0
    ;;
  doorbell-verify)
    output="$(run_success --iterations 12 --threads 2 --doorbell 4 \
      --less-timing --verify --seed 22136)"
    require_verify_counts "$output" 24 0
    ;;
  invalid-memory-mode)
    run_failure "Memory mode must be 0 in emulate mode" \
      --iterations 1 --memory-mode 1
    ;;
  invalid-iterations)
    run_failure "test-ep requires at least one iteration" \
      --iterations 0
    ;;
  invalid-doorbell)
    run_failure "exceeds doorbell queue length" \
      --iterations 1 --threads 2 --doorbell 1
    ;;
  *)
    echo "FAIL: unknown test-ep case: $CASE"
    exit 1
    ;;
esac
