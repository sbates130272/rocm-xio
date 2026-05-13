/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio-timing.h host-side updateTimingStats().
 */

#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "xio-endpoint-core.h"
#include "xio-test-assert.h"
#include "xio-timing.h"

int test_update_timing_stats_nullptr_safe() {
  updateTimingStats(nullptr, 123ULL);
  return 0;
}

int test_update_timing_stats_single_sample() {
  xio::XioTimingStats s{};
  updateTimingStats(&s, 100ULL);
  ASSERT_EQ(s.count, 1ULL);
  ASSERT_EQ(s.sumDuration, 100ULL);
  ASSERT_EQ(s.minDuration, 100ULL);
  ASSERT_EQ(s.maxDuration, 100ULL);
  return 0;
}

int test_update_timing_stats_min_max_tracked() {
  xio::XioTimingStats s{};
  updateTimingStats(&s, 200ULL);
  updateTimingStats(&s, 50ULL);
  updateTimingStats(&s, 150ULL);
  ASSERT_EQ(s.count, 3ULL);
  ASSERT_EQ(s.sumDuration, 400ULL);
  ASSERT_EQ(s.minDuration, 50ULL);
  ASSERT_EQ(s.maxDuration, 200ULL);
  return 0;
}

int main() {
  test_update_timing_stats_nullptr_safe();
  test_update_timing_stats_single_sample();
  test_update_timing_stats_min_max_tracked();
  printf("test-xio-timing: all tests passed\n");
  return 0;
}
