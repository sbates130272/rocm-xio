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

# xio-tester smoke tests in emulate mode. These runs are CPU-only and exercise
# the full CLI path used in CI.
if(TARGET xio-tester)
  set(_xio_tester ${CMAKE_BINARY_DIR}/xio-tester)

  add_test(
    NAME test-ep-cli-emulate
    COMMAND ${_xio_tester}
      test-ep --emulate -n 100 -t 1 -v
  )
  add_test(
    NAME test-ep-cli-emulate-doorbell
    COMMAND ${_xio_tester}
      test-ep --emulate -n 100 -t 1 --doorbell 64 -v
  )
  add_test(
    NAME test-ep-cli-emulate-verify
    COMMAND ${_xio_tester}
      test-ep --emulate -n 100 -t 1 --verify
  )
  add_test(
    NAME test-ep-cli-emulate-doorbell-verify
    COMMAND ${_xio_tester}
      test-ep --emulate -n 100 -t 1 --doorbell 64 --verify
  )

  set(_test_ep_emulate_smoke_tests
    test-ep-cli-emulate
    test-ep-cli-emulate-doorbell
    test-ep-cli-emulate-verify
    test-ep-cli-emulate-doorbell-verify
  )
  set_tests_properties(${_test_ep_emulate_smoke_tests}
    PROPERTIES
      LABELS "system;test-ep;emulate"
      TIMEOUT 120)

  # Negative validation checks for CLI argument handling in emulate mode.
  add_test(
    NAME test-ep-cli-reject-doorbell-too-small
    COMMAND ${_xio_tester}
      test-ep --emulate -n 8 -t 2 --doorbell 1
  )
  set_tests_properties(test-ep-cli-reject-doorbell-too-small
    PROPERTIES
      LABELS "system;test-ep;emulate;negative"
      TIMEOUT 30
      WILL_FAIL TRUE
      PASS_REGULAR_EXPRESSION
      "exceeds doorbell queue length")

  add_test(
    NAME test-ep-cli-reject-emulate-memory-mode
    COMMAND ${_xio_tester}
      test-ep --emulate -m 1
  )
  set_tests_properties(test-ep-cli-reject-emulate-memory-mode
    PROPERTIES
      LABELS "system;test-ep;emulate;negative"
      TIMEOUT 30
      WILL_FAIL TRUE
      PASS_REGULAR_EXPRESSION
      "Memory mode must be 0 in emulate mode")
endif()
