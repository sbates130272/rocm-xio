# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# CPU-only unit tests for the test-ep endpoint.

xio_add_test(
  NAME test-ep-config
  SOURCE test-ep-config.hip
  LABELS unit test-ep
  TIMEOUT 30
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

set(_test_ep_cli_wrapper
  ${CMAKE_CURRENT_SOURCE_DIR}/run-test-ep-cli-test.sh)
set(_xio_tester
  ${CMAKE_BINARY_DIR}/xio-tester)

xio_add_script_test(
  NAME test-ep-cli-emulate
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS unit test-ep cli emulate
  TIMEOUT 30
  ARGS -n 8 -t 1 --less-timing
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-threads
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS unit test-ep cli emulate
  TIMEOUT 30
  ARGS -n 8 -t 2 --less-timing
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-doorbell
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS unit test-ep cli emulate
  TIMEOUT 30
  ARGS -n 8 -t 2 --doorbell 64 --less-timing
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-verify
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS unit test-ep cli emulate verify
  TIMEOUT 30
  ARGS -n 8 -t 2 --verify --seed 7 --less-timing
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
    "EXPECT_VERIFY_PASS=16"
    "EXPECT_VERIFY_FAIL=0"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-doorbell-verify
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS unit test-ep cli emulate verify
  TIMEOUT 30
  ARGS -n 8 -t 2 --doorbell 64 --verify --seed 11 --less-timing
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
    "EXPECT_VERIFY_PASS=16"
    "EXPECT_VERIFY_FAIL=0"
)
