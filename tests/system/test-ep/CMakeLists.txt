# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# System-level tests for test-ep.  These build against the full
# library but the --emulate path runs without a GPU at runtime, so
# the test suite is the canonical CPU-only smoke for the endpoint
# dispatch machinery.

xio_add_test(
  NAME test-ep-emulate
  SOURCE test-ep-emulate.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

# Multi-thread emulation: hits the per-thread SQ/CQ indexing.
xio_add_test(
  NAME test-ep-emulate-multithread
  SOURCE test-ep-emulate-multithread.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

# Doorbell-mode emulation: hits the shared atomic sequence
# counter and the multi-thread barrier.
xio_add_test(
  NAME test-ep-emulate-doorbell
  SOURCE test-ep-emulate-doorbell.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

# Asserts that startTimes / endTimes / XioTimingStats are
# populated by the emulation path (the timing harness self-test).
xio_add_test(
  NAME test-ep-emulate-timing
  SOURCE test-ep-emulate-timing.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)

# Asserts that a fixed CPU response delay is actually honoured.
xio_add_test(
  NAME test-ep-emulate-delay
  SOURCE test-ep-emulate-delay.hip
  LABELS system test-ep
  TIMEOUT 120
  INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/src/endpoints/test-ep
)
