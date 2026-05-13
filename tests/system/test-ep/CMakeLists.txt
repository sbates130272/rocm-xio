# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep (require the full
# library; emulate mode does not need a GPU).

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep emulate
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

set(_xio_tester ${CMAKE_BINARY_DIR}/xio-tester)

add_test(
  NAME test-ep-cli-emulate
  COMMAND ${_xio_tester}
    test-ep --emulate -n 32 -t 1 --less-timing
)
set_tests_properties(test-ep-cli-emulate PROPERTIES
  LABELS "system;test-ep;emulate"
  TIMEOUT 60)

add_test(
  NAME test-ep-cli-emulate-doorbell
  COMMAND ${_xio_tester}
    test-ep --emulate -n 32 -t 1 --doorbell 64 --less-timing
)
set_tests_properties(test-ep-cli-emulate-doorbell PROPERTIES
  LABELS "system;test-ep;emulate"
  TIMEOUT 60)

add_test(
  NAME test-ep-cli-emulate-verify
  COMMAND ${_xio_tester}
    test-ep --emulate -n 32 -t 1 --verify --seed 9 --less-timing
)
set_tests_properties(test-ep-cli-emulate-verify PROPERTIES
  LABELS "system;test-ep;emulate"
  TIMEOUT 60)

add_test(
  NAME test-ep-cli-emulate-doorbell-verify
  COMMAND ${_xio_tester}
    test-ep --emulate -n 32 -t 1 --doorbell 64 --verify --seed 9 --less-timing
)
set_tests_properties(test-ep-cli-emulate-doorbell-verify PROPERTIES
  LABELS "system;test-ep;emulate"
  TIMEOUT 60)

add_test(
  NAME test-ep-cli-reject-emulate-memory-mode
  COMMAND ${_xio_tester}
    test-ep --emulate -m 1
)
set_tests_properties(test-ep-cli-reject-emulate-memory-mode PROPERTIES
  LABELS "system;test-ep;emulate;negative"
  TIMEOUT 30
  WILL_FAIL TRUE
  PASS_REGULAR_EXPRESSION
    "Error: Memory mode must be 0 in emulate mode")

add_test(
  NAME test-ep-cli-reject-doorbell-threads
  COMMAND ${_xio_tester}
    test-ep --emulate --doorbell 2 -t 4
)
set_tests_properties(test-ep-cli-reject-doorbell-threads PROPERTIES
  LABELS "system;test-ep;emulate;negative"
  TIMEOUT 30
  WILL_FAIL TRUE
  PASS_REGULAR_EXPRESSION
    "exceeds doorbell queue length")
