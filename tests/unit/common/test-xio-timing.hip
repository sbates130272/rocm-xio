/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio::updateTimingStats and related timing types.
 */

#include <climits>
#include <cstdio>
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
  xio::XioTimingStats stats = {};
  stats.minDuration = ULLONG_MAX;
  updateTimingStats(&stats, 100ULL);
  ASSERT_EQ(stats.count, 1ULL);
  ASSERT_EQ(stats.sumDuration, 100ULL);
  ASSERT_EQ(stats.minDuration, 100ULL);
  ASSERT_EQ(stats.maxDuration, 100ULL);
  return 0;
}

int test_timing_min_max_updates() {
  xio::XioTimingStats stats = {};
  stats.minDuration = ULLONG_MAX;
  updateTimingStats(&stats, 50ULL);
  updateTimingStats(&stats, 10ULL);
  updateTimingStats(&stats, 90ULL);
  ASSERT_EQ(stats.count, 3ULL);
  ASSERT_EQ(stats.sumDuration, 150ULL);
  ASSERT_EQ(stats.minDuration, 10ULL);
  ASSERT_EQ(stats.maxDuration, 90ULL);
  return 0;
}

int test_substep_stats_defaults() {
  xio::XioSubstepStats s = {};
  ASSERT_EQ(s.sqeBuild, 0ULL);
  ASSERT_EQ(s.sqeEnqueue, 0ULL);
  ASSERT_EQ(s.doorbell, 0ULL);
  ASSERT_EQ(s.cqPoll, 0ULL);
  ASSERT_EQ(s.cqDoorbell, 0ULL);
  ASSERT_EQ(s.count, 0ULL);
  ASSERT_EQ(s.buildCount, 0ULL);
  return 0;
}

int test_endpoint_config_ctor() {
  xio::XioEndpointConfig a;
  ASSERT_EQ(a.iterations, 128u);
  ASSERT_EQ(a.numThreads, 1u);

  xio::XioEndpointConfig b(256, 4);
  ASSERT_EQ(b.iterations, 256u);
  ASSERT_EQ(b.numThreads, 4u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_timing_null_stats();
  failures += test_timing_single_sample();
  failures += test_timing_min_max_updates();
  failures += test_substep_stats_defaults();
  failures += test_endpoint_config_ctor();

  if (failures == 0) {
    printf("All xio-timing tests passed.\n");
    return 0;
  }
  printf("%d xio-timing test(s) failed.\n", failures);
  return 1;
}
