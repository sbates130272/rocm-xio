/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for updateTimingStats() host-side behavior.
 */

#include <climits>
#include <cstdint>
#include <cstdio>
#include <thread>
#include <vector>

#include "xio-test-assert.h"
#include "xio-timing.h"

int test_updateTimingStats_nullptr_noop() {
  updateTimingStats(nullptr, 123);
  return 0;
}

int test_updateTimingStats_sequential() {
  xio::XioTimingStats stats;
  stats.minDuration = ULLONG_MAX;
  stats.maxDuration = 0;
  stats.sumDuration = 0;
  stats.count = 0;

  updateTimingStats(&stats, 40);
  updateTimingStats(&stats, 10);
  updateTimingStats(&stats, 100);

  ASSERT_EQ(stats.count, 3u);
  ASSERT_EQ(stats.sumDuration, 150u);
  ASSERT_EQ(stats.minDuration, 10u);
  ASSERT_EQ(stats.maxDuration, 100u);
  return 0;
}

int test_updateTimingStats_multithreaded() {
  constexpr unsigned kThreads = 4;
  constexpr unsigned kSamplesPerThread = 1000;

  xio::XioTimingStats stats;
  stats.minDuration = ULLONG_MAX;
  stats.maxDuration = 0;
  stats.sumDuration = 0;
  stats.count = 0;

  unsigned long long expectedSum = 0;
  unsigned long long expectedMin = ULLONG_MAX;
  unsigned long long expectedMax = 0;

  for (unsigned t = 0; t < kThreads; ++t) {
    for (unsigned i = 1; i <= kSamplesPerThread; ++i) {
      const unsigned long long value = (t * 1000ULL) + i;
      expectedSum += value;
      if (value < expectedMin) {
        expectedMin = value;
      }
      if (value > expectedMax) {
        expectedMax = value;
      }
    }
  }

  std::vector<std::thread> workers;
  workers.reserve(kThreads);
  for (unsigned t = 0; t < kThreads; ++t) {
    workers.emplace_back([t, &stats]() {
      for (unsigned i = 1; i <= kSamplesPerThread; ++i) {
        updateTimingStats(&stats, (t * 1000ULL) + i);
      }
    });
  }

  for (auto& worker : workers) {
    worker.join();
  }

  ASSERT_EQ(stats.count, static_cast<unsigned long long>(kThreads) *
                           static_cast<unsigned long long>(kSamplesPerThread));
  ASSERT_EQ(stats.sumDuration, expectedSum);
  ASSERT_EQ(stats.minDuration, expectedMin);
  ASSERT_EQ(stats.maxDuration, expectedMax);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_updateTimingStats_nullptr_noop();
  failures += test_updateTimingStats_sequential();
  failures += test_updateTimingStats_multithreaded();

  if (failures == 0) {
    printf("All xio-timing tests passed.\n");
    return 0;
  }

  printf("%d xio-timing test(s) failed.\n", failures);
  return 1;
}
