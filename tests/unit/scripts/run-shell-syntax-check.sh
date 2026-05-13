#!/usr/bin/env bash
# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# CTest helper: run "bash -n" on every tracked *.sh file in the repository.
# Exits 0 when all scripts parse; 1 if any file fails.

set -euo pipefail

cd "$(dirname "$0")/../../.."

fail=0
if git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r -d '' f; do
    if ! bash -n "$f" 2>&1; then
      printf 'shell-syntax: FAILED %s\n' "$f" >&2
      fail=1
    fi
  done < <(git -C "$PWD" ls-files -z -- '*.sh')
else
  while IFS= read -r -d '' f; do
    if ! bash -n "$f" 2>&1; then
      printf 'shell-syntax: FAILED %s\n' "$f" >&2
      fail=1
    fi
  done < <(find "$PWD/scripts" "$PWD/tests" "$PWD/udev" "$PWD/kernel" \
    -name '*.sh' -type f -print0 2>/dev/null)
fi
