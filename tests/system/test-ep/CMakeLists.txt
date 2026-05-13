# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep (HIP runtime and host allocators;
# emulate mode avoids launching GPU kernels).

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

# Exercise the CLI harness against test-ep (same scenarios as CI
# workflow `test-emulate.yml`).
if(TARGET xio-tester)
  add_test(
    NAME test-ep-tester-emulate
    COMMAND $<TARGET_FILE:xio-tester> test-ep --emulate -n 100 -t 1 -v
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

  add_test(
    NAME test-ep-tester-emulate-doorbell
    COMMAND $<TARGET_FILE:xio-tester> test-ep --emulate -n 100 -t 1
            --doorbell 64 -v
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

  add_test(
    NAME test-ep-tester-emulate-verify
    COMMAND $<TARGET_FILE:xio-tester> test-ep --emulate -n 100 -t 1 --verify
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

  add_test(
    NAME test-ep-tester-emulate-doorbell-verify
    COMMAND $<TARGET_FILE:xio-tester> test-ep --emulate -n 100 -t 1
            --doorbell 64 --verify
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

  set_tests_properties(
    test-ep-tester-emulate test-ep-tester-emulate-doorbell
    test-ep-tester-emulate-verify test-ep-tester-emulate-doorbell-verify
    PROPERTIES LABELS "system;test-ep" TIMEOUT 180)
endif()
