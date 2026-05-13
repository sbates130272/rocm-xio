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

set(_wrapper
  ${CMAKE_CURRENT_SOURCE_DIR}/run-test-ep-script-test.sh)
set(_xio_tester
  ${CMAKE_BINARY_DIR}/xio-tester)

xio_add_script_test(
  NAME test-ep-cli-emulate
  SCRIPT ${_wrapper}
  LABELS system test-ep smoke
  TIMEOUT 60
  ARGS --emulate -n 64 -t 1 --less-timing
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-doorbell
  SCRIPT ${_wrapper}
  LABELS system test-ep smoke
  TIMEOUT 60
  ARGS --emulate -n 64 -t 4 --doorbell 64 --less-timing
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-verify
  SCRIPT ${_wrapper}
  LABELS system test-ep verify
  TIMEOUT 60
  ARGS --emulate -n 64 -t 2 --verify --seed 85 --less-timing
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
    "REQUIRE_VERIFY=1"
)

xio_add_script_test(
  NAME test-ep-cli-reject-emulate-memory-mode
  SCRIPT ${_wrapper}
  LABELS system test-ep negative
  TIMEOUT 30
  ARGS --emulate -n 8 -m 1
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
    "EXPECT_FAIL=1"
)

xio_add_script_test(
  NAME test-ep-cli-reject-verify-doorbell
  SCRIPT ${_wrapper}
  LABELS system test-ep negative
  TIMEOUT 30
  ARGS --emulate -n 8 -t 2 --doorbell 32 --verify
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
    "EXPECT_FAIL=1"
)
