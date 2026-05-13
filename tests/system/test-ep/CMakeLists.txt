# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep (HIP + rocm-xio; labelled ``system`` like
# other GPU-oriented tests). ``test-ep-emulate`` exercises the library API;
# ``test-ep-cli-*`` runs ``xio-tester`` with the same flag combinations as
# ``.github/workflows/test-emulate.yml``.

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

if(BUILD_CLIENTS)
  set(_xio_tester "${CMAKE_BINARY_DIR}/xio-tester")

  add_test(
    NAME test-ep-cli-emulate-basic
    COMMAND ${_xio_tester} test-ep --emulate -n 100 -t 1 -v --less-timing
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  set_tests_properties(test-ep-cli-emulate-basic PROPERTIES
    LABELS "system;test-ep;cli"
    TIMEOUT 120)

  add_test(
    NAME test-ep-cli-emulate-doorbell
    COMMAND ${_xio_tester} test-ep --emulate -n 100 -t 1 --doorbell 64 -v
      --less-timing
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  set_tests_properties(test-ep-cli-emulate-doorbell PROPERTIES
    LABELS "system;test-ep;cli"
    TIMEOUT 120)

  add_test(
    NAME test-ep-cli-emulate-verify
    COMMAND ${_xio_tester} test-ep --emulate -n 100 -t 1 --verify --less-timing
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  set_tests_properties(test-ep-cli-emulate-verify PROPERTIES
    LABELS "system;test-ep;cli"
    TIMEOUT 120)

  add_test(
    NAME test-ep-cli-emulate-doorbell-verify
    COMMAND ${_xio_tester} test-ep --emulate -n 100 -t 1 --doorbell 64
      --verify --less-timing
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  set_tests_properties(test-ep-cli-emulate-doorbell-verify PROPERTIES
    LABELS "system;test-ep;cli"
    TIMEOUT 120)
endif()
