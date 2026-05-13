/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for updateTimingStats() host-side aggregation in xio-timing.h.
 */

#include <climits>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <hip/hip_runtime.h>

#include "xio-endpoint-core.h"
#include "xio-test-assert.h"
#include "xio-timing.h"

int test_timing_null_stats() {
  updateTimingStats(nullptr, 123ULL);
  return 0;
}

int test_timing_single_sample() {
  xio::XioTimingStats st = {};
  memset(&st, 0, sizeof(st));
  st.minDuration = ULLONG_MAX;
  updateTimingStats(&st, 100ULL);
  ASSERT_EQ(st.count, 1ULL);
  ASSERT_EQ(st.sumDuration, 100ULL);
  ASSERT_EQ(st.minDuration, 100ULL);
  ASSERT_EQ(st.maxDuration, 100ULL);
  return 0;
}

int test_timing_min_max() {
  xio::XioTimingStats st = {};
  memset(&st, 0, sizeof(st));
  st.minDuration = ULLONG_MAX;
  updateTimingStats(&st, 50ULL);
  updateTimingStats(&st, 10ULL);
  updateTimingStats(&st, 200ULL);
  ASSERT_EQ(st.count, 3ULL);
  ASSERT_EQ(st.sumDuration, 260ULL);
  ASSERT_EQ(st.minDuration, 10ULL);
  ASSERT_EQ(st.maxDuration, 200ULL);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_timing_null_stats();
  failures += test_timing_single_sample();
  failures += test_timing_min_max();
  if (failures == 0) {
    printf("All xio-timing tests passed.\n");
    return 0;
  }
  printf("%d xio-timing test(s) failed.\n", failures);
  return 1;
}
