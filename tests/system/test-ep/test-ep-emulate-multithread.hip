/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * System-level test for test-ep emulate mode with multiple threads.
 */

#include <cstdio>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"
#include "xio.h"

int test_emulate_multithread_roundtrip() {
  const unsigned kIter = 24;
  const unsigned kThreads = 4;

  xio::XioEndpointConfig cfg(kIter, kThreads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = kIter;
  cfg.endpointConfig = &epCfg;

  const size_t sqSize = kThreads * sizeof(xio::test_ep::test_sqe);
  const size_t cqSize = kThreads * sizeof(xio::test_ep::test_cqe);

  void* sq = nullptr;
  void* cq = nullptr;
  hipError_t sq_err = xio::allocHostMemory(
    sqSize, &sq, "emulate multithread SQ", XIO_HOST_MEM_PLAIN);
  hipError_t cq_err = xio::allocHostMemory(
    cqSize, &cq, "emulate multithread CQ", XIO_HOST_MEM_PLAIN);
  if (sq_err != hipSuccess || cq_err != hipSuccess) {
    xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
    xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);
    fprintf(stderr, "Allocation failed\n");
    return 1;
  }

  cfg.submissionQueue = sq;
  cfg.completionQueue = cq;
  cfg.delayNs = 500;

  hipError_t err = xio::test_ep::run(&cfg);

  xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
  xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);

  if (err != hipSuccess) {
    fprintf(stderr, "test-ep emulate multithread run failed: %d\n",
            static_cast<int>(err));
    return 1;
  }
  return 0;
}

int main() {
  int failures = 0;
  failures += test_emulate_multithread_roundtrip();

  if (failures == 0) {
    printf("All test-ep emulate multithread tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate multithread test(s) failed.\n", failures);
  return 1;
}
