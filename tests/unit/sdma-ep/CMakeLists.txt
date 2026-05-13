# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# CPU-only unit tests for the sdma-ep endpoint.

xio_add_test(
  NAME test-sdma-config
  SOURCE test-sdma-config.hip
  LABELS unit sdma
  TIMEOUT 30
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
)

xio_add_test(
  NAME test-sdma-opcodes
  SOURCE test-sdma-opcodes.hip
  LABELS unit sdma
  TIMEOUT 30
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
)
