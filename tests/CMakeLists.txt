# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# Top-level test coordinator for rocm-xio.
#
# Label convention (filter with ctest -L):
#   unit        - CPU-only, no GPU or NIC required
#   system      - Requires a HIP-capable GPU
#   hardware    - Requires specific NIC/device hardware
#   stress      - Long-running concurrency tests
#   rdma        - RDMA-specific tests
#   integration - Install + build examples against prefix

find_package(Python3 COMPONENTS Interpreter QUIET)
if(Python3_FOUND)
  add_test(
    NAME validate-ctest-resources-json
    COMMAND ${Python3_EXECUTABLE} -c
      "import json; json.load(open(r'${CMAKE_BINARY_DIR}/ctest-resources.json'))"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  set_tests_properties(validate-ctest-resources-json PROPERTIES
    LABELS "unit;build"
    TIMEOUT 10)
endif()

if(TARGET xio-tester)
  add_test(NAME smoke-xio-tester-help COMMAND xio-tester --help)
  set_tests_properties(smoke-xio-tester-help PROPERTIES
    LABELS "unit;tool"
    TIMEOUT 30)
endif()

add_subdirectory(unit)
add_subdirectory(system)
add_subdirectory(integration)
