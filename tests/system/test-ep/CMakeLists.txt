# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep (require the full
# library; emulate mode does not need a GPU).

set(_test_ep_cli_wrapper
  ${CMAKE_CURRENT_SOURCE_DIR}/run-xio-tester-test-ep.sh)
set(_xio_tester
  ${CMAKE_BINARY_DIR}/xio-tester)

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep emulate
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

xio_add_script_test(
  NAME test-ep-cli-emulate
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS system test-ep emulate cli
  TIMEOUT 30
  ARGS smoke
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-verify
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS system test-ep emulate cli verify
  TIMEOUT 30
  ARGS verify
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-emulate-doorbell-verify
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS system test-ep emulate cli verify
  TIMEOUT 30
  ARGS doorbell-verify
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-invalid-memory-mode
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS system test-ep emulate cli negative
  TIMEOUT 30
  ARGS invalid-memory-mode
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-invalid-iterations
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS system test-ep emulate cli negative
  TIMEOUT 30
  ARGS invalid-iterations
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)

xio_add_script_test(
  NAME test-ep-cli-invalid-doorbell
  SCRIPT ${_test_ep_cli_wrapper}
  LABELS system test-ep emulate cli negative
  TIMEOUT 30
  ARGS invalid-doorbell
  ENVIRONMENT "XIO_TESTER=${_xio_tester}"
)
