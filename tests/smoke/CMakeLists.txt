# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# Fast repository sanity checks (no HIP compile).

xio_add_script_test(
  NAME smoke-cmake-presets
  SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/verify-cmake-presets.sh
  LABELS unit
  TIMEOUT 30
)
