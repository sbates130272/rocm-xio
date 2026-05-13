#!/bin/bash
# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Thin wrapper for CPU-only xio-tester test-ep emulation tests.
# All arguments are passed after "xio-tester test-ep --emulate".

set -euo pipefail

XIO_TESTER="${XIO_TESTER:-./build/xio-tester}"

if [ ! -x "$XIO_TESTER" ]; then
    echo "SKIP: xio-tester not found or not executable at $XIO_TESTER"
    exit 77
fi

output="$("$XIO_TESTER" test-ep --emulate "$@" 2>&1)" || {
    status=$?
    echo "$output"
    exit "$status"
}

echo "$output"

if [[ "$output" != *"Using endpoint: test-ep"* ]]; then
    echo "FAIL: output did not report the test-ep endpoint"
    exit 1
fi

if [[ "$output" != *"Test completed successfully!"* ]]; then
    echo "FAIL: output did not report successful completion"
    exit 1
fi

if [ -n "${EXPECT_VERIFY_PASS:-}" ]; then
    if ! [[ "$output" =~ Verify[[:space:]]Passed:[[:space:]]+${EXPECT_VERIFY_PASS} ]]; then
        echo "FAIL: expected Verify Passed count ${EXPECT_VERIFY_PASS}"
        exit 1
    fi
fi

if [ -n "${EXPECT_VERIFY_FAIL:-}" ]; then
    if ! [[ "$output" =~ Verify[[:space:]]Failed:[[:space:]]+${EXPECT_VERIFY_FAIL} ]]; then
        echo "FAIL: expected Verify Failed count ${EXPECT_VERIFY_FAIL}"
        exit 1
    fi
fi
