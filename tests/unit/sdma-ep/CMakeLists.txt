# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# SDMA packet layout and opcode constants (CPU-only; headers carry static_assert).

if(XIO_SDMA_OSS7)
  xio_add_test(
    NAME test-sdma-packets
    SOURCE test-sdma-packets.hip
    LABELS unit sdma
    TIMEOUT 30
    INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
    COMPILE_DEFINITIONS XIO_SDMA_OSS7=1
  )
else()
  xio_add_test(
    NAME test-sdma-packets
    SOURCE test-sdma-packets.hip
    LABELS unit sdma
    TIMEOUT 30
    INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
  )
endif()
