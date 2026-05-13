# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# CPU-only unit tests for SDMA opcode headers.

xio_add_test(
  NAME test-sdma-opcodes
  SOURCE test-sdma-opcodes.hip
  LABELS unit sdma
  TIMEOUT 30
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
)

if(XIO_SDMA_OSS7)
  target_compile_definitions(test-sdma-opcodes PRIVATE XIO_SDMA_OSS7=1)
endif()
