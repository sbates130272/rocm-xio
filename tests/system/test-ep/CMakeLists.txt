# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep (require the full
# library; emulate mode does not need a GPU).

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

xio_add_test(
  NAME test-ep-emulate-doorbell
  SOURCE test-ep-emulate-doorbell.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

xio_add_test(
  NAME test-ep-emulate-multithread
  SOURCE test-ep-emulate-multithread.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)
