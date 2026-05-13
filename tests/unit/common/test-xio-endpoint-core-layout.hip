/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Compile-time and runtime layout checks for xio-endpoint-core.h POD types.
 */

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "xio-endpoint-core.h"
#include "xio-test-assert.h"

int test_timing_stats_size() {
  static_assert(sizeof(xio::XioTimingStats) == 4 * sizeof(unsigned long long),
                "XioTimingStats layout");
  return 0;
}

int test_substep_stats_offsets() {
  xio::XioSubstepStats s = {};
  s.sqeBuild = 1;
  s.count = 2;
  ASSERT_EQ(s.sqeBuild, 1ULL);
  ASSERT_EQ(s.count, 2ULL);
  return 0;
}

int test_endpoint_config_defaults() {
  xio::XioEndpointConfig c;
  ASSERT_EQ(c.iterations, 128u);
  ASSERT_EQ(c.numThreads, 1u);
  ASSERT_EQ(c.memoryMode, 0u);
  ASSERT_TRUE(c.startTimes == nullptr);
  ASSERT_TRUE(c.timingStats == nullptr);
  ASSERT_TRUE(c.substepStats == nullptr);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_timing_stats_size();
  failures += test_substep_stats_offsets();
  failures += test_endpoint_config_defaults();
  if (failures == 0) {
    printf("All xio-endpoint-core layout tests passed.\n");
    return 0;
  }
  printf("%d xio-endpoint-core layout test(s) failed.\n", failures);
  return 1;
}
