/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for host-side XioTimingStats aggregation.
 */

#include <climits>
#include <cstdio>

#include "xio-test-assert.h"
#include "xio-timing.h"

int test_default_stats_values() {
  xio::XioTimingStats stats;
  ASSERT_EQ(stats.minDuration, ULLONG_MAX);
  ASSERT_EQ(stats.maxDuration, 0ULL);
  ASSERT_EQ(stats.sumDuration, 0ULL);
  ASSERT_EQ(stats.count, 0ULL);
  return 0;
}

int test_update_timing_stats_ignores_null() {
  updateTimingStats(nullptr, 1234);
  return 0;
}

int test_update_timing_stats_single_sample() {
  xio::XioTimingStats stats;
  updateTimingStats(&stats, 37);

  ASSERT_EQ(stats.count, 1ULL);
  ASSERT_EQ(stats.sumDuration, 37ULL);
  ASSERT_EQ(stats.minDuration, 37ULL);
  ASSERT_EQ(stats.maxDuration, 37ULL);
  return 0;
}

int test_update_timing_stats_multiple_samples() {
  xio::XioTimingStats stats;
  updateTimingStats(&stats, 40);
  updateTimingStats(&stats, 10);
  updateTimingStats(&stats, 70);
  updateTimingStats(&stats, 25);

  ASSERT_EQ(stats.count, 4ULL);
  ASSERT_EQ(stats.sumDuration, 145ULL);
  ASSERT_EQ(stats.minDuration, 10ULL);
  ASSERT_EQ(stats.maxDuration, 70ULL);
  return 0;
}

int test_update_timing_stats_preserves_existing_extrema() {
  xio::XioTimingStats stats;
  stats.minDuration = 5;
  stats.maxDuration = 100;
  stats.sumDuration = 7;
  stats.count = 2;

  updateTimingStats(&stats, 50);

  ASSERT_EQ(stats.count, 3ULL);
  ASSERT_EQ(stats.sumDuration, 57ULL);
  ASSERT_EQ(stats.minDuration, 5ULL);
  ASSERT_EQ(stats.maxDuration, 100ULL);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_default_stats_values();
  failures += test_update_timing_stats_ignores_null();
  failures += test_update_timing_stats_single_sample();
  failures += test_update_timing_stats_multiple_samples();
  failures += test_update_timing_stats_preserves_existing_extrema();

  if (failures == 0) {
    printf("All xio-timing tests passed.\n");
    return 0;
  }
  printf("%d xio-timing test(s) failed.\n", failures);
  return 1;
}
