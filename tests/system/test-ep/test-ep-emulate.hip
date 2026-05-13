/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * System-level test for test-ep in emulate mode.
 *
 * Validates the full SQE/CQE roundtrip using CPU emulation threads. This
 * exercises the same code path as `xio-tester test-ep --emulate` but through
 * the library API with a minimal configuration.
 */

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"
#include "xio.h"

int run_emulate_case(unsigned iterations, unsigned threads, unsigned doorbell,
                     bool verify) {
  xio::XioEndpointConfig cfg(iterations, threads);
  cfg.delayNs = -1000;

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = iterations;
  epCfg.doorbell = doorbell;
  epCfg.verify = verify;
  epCfg.seed = 0x1234u;
  cfg.endpointConfig = &epCfg;

  const size_t queueLength = (doorbell > 0) ? static_cast<size_t>(doorbell)
                                            : ((threads > 1) ? threads : 1);
  const size_t sqSize = queueLength * sizeof(xio::test_ep::test_sqe);
  const size_t cqSize = queueLength * sizeof(xio::test_ep::test_cqe);
  const size_t timingEntries = static_cast<size_t>(iterations) * threads;

  std::vector<unsigned long long> startTimes(timingEntries, 0);
  std::vector<unsigned long long> endTimes(timingEntries, 0);
  cfg.startTimes = startTimes.data();
  cfg.endTimes = endTimes.data();

  void* sq = nullptr;
  void* cq = nullptr;
  hipError_t sqErr = xio::allocHostMemory(sqSize, &sq, "emulate SQ",
                                          XIO_HOST_MEM_PLAIN);
  hipError_t cqErr = xio::allocHostMemory(cqSize, &cq, "emulate CQ",
                                          XIO_HOST_MEM_PLAIN);
  if (sqErr != hipSuccess || cqErr != hipSuccess) {
    xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
    xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);
    fprintf(stderr, "Allocation failed\n");
    return 1;
  }
  cfg.submissionQueue = sq;
  cfg.completionQueue = cq;

  const hipError_t err = xio::test_ep::run(&cfg);

  xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
  xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);

  if (err != hipSuccess) {
    fprintf(stderr, "test-ep emulate run failed: %d\n", static_cast<int>(err));
    return 1;
  }

  bool sawPositiveDuration = false;
  for (size_t i = 0; i < timingEntries; ++i) {
    ASSERT_GE(endTimes[i], startTimes[i]);
    if (endTimes[i] > startTimes[i]) {
      sawPositiveDuration = true;
    }
  }
  ASSERT_TRUE(sawPositiveDuration);

  if (verify) {
    ASSERT_EQ(cfg.verifyPass, iterations * threads);
    ASSERT_EQ(cfg.verifyFail, 0u);
  } else {
    ASSERT_EQ(cfg.verifyFail, 0u);
  }

  return 0;
}

int test_emulate_roundtrip() {
  return run_emulate_case(10, 1, 0, false);
}

int test_emulate_multithread_roundtrip() {
  return run_emulate_case(24, 4, 0, false);
}

int test_emulate_doorbell_roundtrip() {
  return run_emulate_case(24, 4, 64, false);
}

int test_emulate_verify_roundtrip() {
  return run_emulate_case(12, 2, 0, true);
}

int main() {
  int failures = 0;
  failures += test_emulate_roundtrip();
  failures += test_emulate_multithread_roundtrip();
  failures += test_emulate_doorbell_roundtrip();
  failures += test_emulate_verify_roundtrip();

  if (failures == 0) {
    printf("All test-ep emulate tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate test(s) failed.\n", failures);
  return 1;
}
