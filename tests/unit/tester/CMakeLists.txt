# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# CPU-only unit tests for xio-tester CLI option helpers.

xio_add_test(
  NAME test-xio-cli-options
  SOURCE test-xio-cli-options.hip
  LABELS unit tester
  TIMEOUT 30
  INCLUDE_DIRS
    ${CMAKE_SOURCE_DIR}/src/tester
    ${CMAKE_SOURCE_DIR}/src/endpoints/nvme-ep
    ${CMAKE_SOURCE_DIR}/src/endpoints/rdma-ep
    ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
    ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)
