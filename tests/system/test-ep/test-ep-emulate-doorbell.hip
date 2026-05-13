/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * System-level emulate-mode test for test-ep doorbell queue operation.
 */

#include <cstdint>
#include <cstdio>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"
#include "xio.h"

int test_emulate_doorbell_roundtrip() {
  const unsigned kIterations = 64;
  const unsigned kThreads = 4;
  const unsigned kQueueDepth = 128;

  xio::XioEndpointConfig cfg(kIterations, kThreads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.doorbell = kQueueDepth;
  epCfg.iterations = kIterations;
  cfg.endpointConfig = &epCfg;

  const size_t sqSize = kQueueDepth * sizeof(xio::test_ep::test_sqe);
  const size_t cqSize = kQueueDepth * sizeof(xio::test_ep::test_cqe);

  void* sq = nullptr;
  void* cq = nullptr;
  hipError_t sqErr = xio::allocHostMemory(sqSize, &sq, "emulate doorbell SQ",
                                          XIO_HOST_MEM_PLAIN);
  hipError_t cqErr = xio::allocHostMemory(cqSize, &cq, "emulate doorbell CQ",
                                          XIO_HOST_MEM_PLAIN);
  if (sqErr != hipSuccess || cqErr != hipSuccess) {
    xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
    xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);
    return 1;
  }

  cfg.submissionQueue = sq;
  cfg.completionQueue = cq;

  hipError_t runErr = xio::test_ep::run(&cfg);

  unsigned completions = 0;
  if (runErr == hipSuccess) {
    auto* cqEntries = static_cast<xio::test_ep::test_cqe*>(cq);
    for (unsigned i = 0; i < kQueueDepth; i++) {
      if (cqEntries[i].magic == xio::test_ep::cqeMagicId) {
        completions++;
      }
    }
  }

  xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
  xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);

  ASSERT_EQ(runErr, hipSuccess);
  ASSERT_GT(completions, 0u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_emulate_doorbell_roundtrip();

  if (failures == 0) {
    printf("All test-ep emulate doorbell tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate doorbell test(s) failed.\n", failures);
  return 1;
}
