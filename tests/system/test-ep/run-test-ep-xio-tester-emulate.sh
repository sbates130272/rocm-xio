#!/usr/bin/env bash
# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# CTest driver for xio-tester test-ep in CPU emulation mode. Mirrors the
# pull-request workflow so local ``ctest`` runs catch CLI regressions.
#
# Environment:
#   XIO_TESTER  Path to the xio-tester binary (required).

set -euo pipefail

XIO_TESTER="${XIO_TESTER:-}"

if [[ -z "${XIO_TESTER}" ]]; then
  echo "SKIP: XIO_TESTER is not set" >&2
  exit 77
fi

if [[ ! -x "${XIO_TESTER}" && ! -f "${XIO_TESTER}" ]]; then
  echo "SKIP: xio-tester not found at ${XIO_TESTER}" >&2
  exit 77
fi

run_case() {
  echo "+ ${*}" >&2
  "${@}"
}

# Keep workloads small for fast CTest; behavior matches CI coverage.
run_case "${XIO_TESTER}" test-ep --emulate -n 50 -t 1 -v
run_case "${XIO_TESTER}" test-ep --emulate -n 50 -t 1 --doorbell 64 -v
run_case "${XIO_TESTER}" test-ep --emulate -n 50 -t 1 --verify
run_case "${XIO_TESTER}" test-ep --emulate -n 50 -t 1 --doorbell 64 --verify

echo "All xio-tester test-ep emulate smoke cases passed." >&2
