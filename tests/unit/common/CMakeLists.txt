# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# CPU-only unit tests for common library code.

xio_add_test(
  NAME test-data-pattern
  SOURCE test-data-pattern.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-rdma-topology
  SOURCE test-rdma-topology.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-extract-endpoint
  SOURCE test-extract-endpoint.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-rocm-xio-uapi-layout
  SOURCE test-rocm-xio-uapi-layout.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-endpoint-registry
  SOURCE test-endpoint-registry.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-xio-env
  SOURCE test-xio-env.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-xio-timing
  SOURCE test-xio-timing.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-tcp-exchange-msg
  SOURCE test-tcp-exchange-msg.hip
  LABELS unit common
  TIMEOUT 30
)

xio_add_test(
  NAME test-sdma-constants
  SOURCE test-sdma-constants.hip
  LABELS unit common
  TIMEOUT 30
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/sdma-ep
)

if(XIO_SDMA_OSS7)
  target_compile_definitions(test-sdma-constants PRIVATE XIO_SDMA_OSS7=1)
endif()

# Subprocess checks for rocxioLogLevel() (static init reads env once per
# process).  Use env(1) to drop inherited ROCXIO_* variables from the
# outer shell so results stay deterministic under ctest.
add_test(
  NAME test-xio-env-log-default
  COMMAND env -u ROCXIO_LOG_LEVEL -u ROCXIO_VERBOSE
    "$<TARGET_FILE:test-xio-env>" --expect-log 2)
set_tests_properties(test-xio-env-log-default PROPERTIES
  LABELS "unit;common"
  TIMEOUT 30)

foreach(_lvl RANGE 0 5)
  add_test(
    NAME test-xio-env-log-level-${_lvl}
    COMMAND env -u ROCXIO_VERBOSE "ROCXIO_LOG_LEVEL=${_lvl}"
      "$<TARGET_FILE:test-xio-env>" --expect-log ${_lvl})
  set_tests_properties(test-xio-env-log-level-${_lvl} PROPERTIES
    LABELS "unit;common"
    TIMEOUT 30)
endforeach()

add_test(
  NAME test-xio-env-log-invalid
  COMMAND env -u ROCXIO_VERBOSE ROCXIO_LOG_LEVEL=not-a-number
    "$<TARGET_FILE:test-xio-env>" --expect-log 2)
set_tests_properties(test-xio-env-log-invalid PROPERTIES
  LABELS "unit;common"
  TIMEOUT 30)

add_test(
  NAME test-xio-env-log-clamp-low
  COMMAND env -u ROCXIO_VERBOSE ROCXIO_LOG_LEVEL=-50
    "$<TARGET_FILE:test-xio-env>" --expect-log 0)
set_tests_properties(test-xio-env-log-clamp-low PROPERTIES
  LABELS "unit;common"
  TIMEOUT 30)

add_test(
  NAME test-xio-env-log-clamp-high
  COMMAND env -u ROCXIO_VERBOSE ROCXIO_LOG_LEVEL=500
    "$<TARGET_FILE:test-xio-env>" --expect-log 5)
set_tests_properties(test-xio-env-log-clamp-high PROPERTIES
  LABELS "unit;common"
  TIMEOUT 30)

add_test(
  NAME test-xio-env-log-verbose-bump
  COMMAND env ROCXIO_LOG_LEVEL=1 ROCXIO_VERBOSE=1
    "$<TARGET_FILE:test-xio-env>" --expect-log 3)
set_tests_properties(test-xio-env-log-verbose-bump PROPERTIES
  LABELS "unit;common"
  TIMEOUT 30)
