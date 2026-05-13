#!/bin/bash
# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Wrapper for xio-tester test-ep emulate CTests.
# Maps missing prerequisites to CTest skip (exit 77),
# supports expected-failure tests, and can assert
# verify counters are printed and successful.

set -euo pipefail

XIO_TESTER="${XIO_TESTER:-./build/xio-tester}"

if [ ! -f "$XIO_TESTER" ]; then
  echo "SKIP: xio-tester not found at $XIO_TESTER"
  exit 77
fi

if [ "$#" -eq 0 ]; then
  echo "SKIP: no xio-tester arguments provided"
  exit 77
fi

output=""
status=0
if output="$("$XIO_TESTER" test-ep "$@" 2>&1)"; then
  status=0
else
  status=$?
fi

if [ "${EXPECT_FAIL:-0}" = "1" ]; then
  if [ "$status" -eq 0 ]; then
    printf '%s\n' "$output"
    echo "FAIL: expected failure but command succeeded"
    exit 1
  fi
  printf '%s\n' "$output"
  echo "OK: command failed as expected"
  exit 0
fi

if [ "$status" -ne 0 ]; then
  printf '%s\n' "$output"
  exit "$status"
fi

if [ "${REQUIRE_VERIFY:-0}" = "1" ]; then
  pass_count="$(printf '%s\n' "$output" | awk '/Verify Passed:/ {print $NF}')"
  fail_count="$(printf '%s\n' "$output" | awk '/Verify Failed:/ {print $NF}')"

  if [ -z "$pass_count" ] || [ -z "$fail_count" ]; then
    printf '%s\n' "$output"
    echo "FAIL: expected verify counters in output"
    exit 1
  fi

  if [ "$fail_count" -ne 0 ]; then
    printf '%s\n' "$output"
    echo "FAIL: verification failures reported: $fail_count"
    exit 1
  fi

  if [ "$pass_count" -le 0 ]; then
    printf '%s\n' "$output"
    echo "FAIL: verify pass count must be > 0"
    exit 1
  fi
fi

printf '%s\n' "$output"
