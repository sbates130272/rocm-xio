# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# CPU-only unit tests for shared xio-tester CLI parsing.
if(BUILD_CLIENTS)
  xio_add_test(
    NAME test-cli-options
    SOURCE test-cli-options.hip
    LABELS unit tester
    TIMEOUT 30
    INCLUDE_DIRS
      ${CMAKE_SOURCE_DIR}/src/tester
      ${CMAKE_SOURCE_DIR}/src/common
      ${CMAKE_SOURCE_DIR}/src/endpoints/nvme-ep
      ${CMAKE_SOURCE_DIR}/src/endpoints/rdma-ep
      ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
      ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
  )
endif()
