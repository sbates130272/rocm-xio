/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * System-level test for test-ep in emulate + doorbell mode.
 * Exercises the shared atomic sequence counter and the multi-
 * thread barrier in `endpoint_kernel_cpu_emulate`.  The doorbell
 * queue is sized 2x the per-iteration footprint so a single
 * iteration never wraps.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"
#include "xio.h"

int test_emulate_doorbell() {
  const unsigned kIter = 8;
  const unsigned kThreads = 4;
  const unsigned kQueueSize = 16;

  xio::XioEndpointConfig cfg(kIter, kThreads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = kIter;
  epCfg.doorbell = kQueueSize;
  cfg.endpointConfig = &epCfg;

  size_t sqSize = kQueueSize * sizeof(xio::test_ep::test_sqe);
  size_t cqSize = kQueueSize * sizeof(xio::test_ep::test_cqe);

  void *sq = nullptr, *cq = nullptr;
  hipError_t sqErr = xio::allocHostMemory(sqSize, &sq, "doorbell SQ",
                                          XIO_HOST_MEM_PLAIN);
  hipError_t cqErr = xio::allocHostMemory(cqSize, &cq, "doorbell CQ",
                                          XIO_HOST_MEM_PLAIN);
  if (sqErr != hipSuccess || cqErr != hipSuccess) {
    xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
    xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);
    fprintf(stderr, "Allocation failed\n");
    return 1;
  }

  cfg.submissionQueue = sq;
  cfg.completionQueue = cq;

  hipError_t err = xio::test_ep::run(&cfg);

  xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
  xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);

  ASSERT_EQ(err, hipSuccess);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_emulate_doorbell();

  if (failures == 0) {
    printf("All test-ep emulate-doorbell tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate-doorbell test(s) failed.\n", failures);
  return 1;
}
