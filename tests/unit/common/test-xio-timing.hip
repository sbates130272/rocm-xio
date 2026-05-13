/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Host-side unit tests for updateTimingStats() in xio-timing.h.
 */

#include <climits>
#include <cstdio>

#include <hip/hip_runtime.h>

#include "xio-endpoint-core.h"
#include "xio-test-assert.h"
#include "xio-timing.h"

static int test_null_stats_ignored() {
  updateTimingStats(nullptr, 123ULL);
  return 0;
}

static int test_single_sample() {
  xio::XioTimingStats s{};
  updateTimingStats(&s, 100ULL);
  ASSERT_EQ(s.count, 1ULL);
  ASSERT_EQ(s.sumDuration, 100ULL);
  ASSERT_EQ(s.minDuration, 100ULL);
  ASSERT_EQ(s.maxDuration, 100ULL);
  return 0;
}

static int test_min_max_tracked() {
  xio::XioTimingStats s{};
  updateTimingStats(&s, 50ULL);
  updateTimingStats(&s, 10ULL);
  updateTimingStats(&s, 200ULL);
  ASSERT_EQ(s.count, 3ULL);
  ASSERT_EQ(s.sumDuration, 260ULL);
  ASSERT_EQ(s.minDuration, 10ULL);
  ASSERT_EQ(s.maxDuration, 200ULL);
  return 0;
}

static int test_equal_min_max() {
  xio::XioTimingStats s{};
  updateTimingStats(&s, 77ULL);
  updateTimingStats(&s, 77ULL);
  ASSERT_EQ(s.minDuration, 77ULL);
  ASSERT_EQ(s.maxDuration, 77ULL);
  ASSERT_EQ(s.count, 2ULL);
  ASSERT_EQ(s.sumDuration, 154ULL);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_null_stats_ignored();
  failures += test_single_sample();
  failures += test_min_max_tracked();
  failures += test_equal_min_max();

  if (failures == 0) {
    printf("All xio-timing unit tests passed.\n");
    return 0;
  }
  printf("%d xio-timing test(s) failed.\n", failures);
  return 1;
}
