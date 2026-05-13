# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep (HIP runtime + rocm-xio; emulate mode uses
# CPU threads and host allocations, so a discrete GPU is not required).

set(_xio_tester ${CMAKE_BINARY_DIR}/xio-tester)
set(_test_ep_tester_script
  ${CMAKE_CURRENT_SOURCE_DIR}/run-test-ep-xio-tester-emulate.sh)

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

# Exercise the CLI entry point (same matrix as .github/workflows/test-emulate.yml).
xio_add_script_test(
  NAME test-ep-xio-tester-emulate-smoke
  SCRIPT ${_test_ep_tester_script}
  LABELS system test-ep smoke
  TIMEOUT 120
  ENVIRONMENT
    "XIO_TESTER=${_xio_tester}"
)
