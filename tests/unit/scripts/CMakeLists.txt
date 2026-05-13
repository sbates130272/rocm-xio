# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# Fast CPU-only checks (no GPU, no hardware devices).

xio_add_script_test(
  NAME shell-syntax-all-repo-sh
  SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/run-shell-syntax-check.sh
  LABELS unit
  TIMEOUT 120
)
