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

#include <cstdint>
#include <cstdio>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"
#include "xio.h"

int run_emulate_case(const char* name, unsigned iterations, unsigned threads,
                     unsigned doorbell, bool verify) {
  if (doorbell > 0 && threads > doorbell) {
    fprintf(stderr, "%s: invalid case (threads > doorbell)\n", name);
    return 1;
  }

  xio::XioEndpointConfig cfg(iterations, threads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = iterations;
  epCfg.doorbell = doorbell;
  epCfg.verify = verify;
  epCfg.seed = 7;
  cfg.endpointConfig = &epCfg;

  size_t queueLen = (doorbell > 0) ? doorbell : ((threads > 1) ? threads : 1);
  size_t sqSize = queueLen * sizeof(xio::test_ep::test_sqe);
  size_t cqSize = queueLen * sizeof(xio::test_ep::test_cqe);

  void *sq = nullptr, *cq = nullptr;
  hipError_t sq_err = xio::allocHostMemory(sqSize, &sq, "emulate SQ",
                                           XIO_HOST_MEM_PLAIN);
  hipError_t cq_err = xio::allocHostMemory(cqSize, &cq, "emulate CQ",
                                           XIO_HOST_MEM_PLAIN);
  if (sq_err != hipSuccess || cq_err != hipSuccess) {
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

  if (err != hipSuccess) {
    fprintf(stderr, "%s failed: %d\n", name, static_cast<int>(err));
    return 1;
  }

  if (verify) {
    unsigned expected = iterations * threads;
    ASSERT_EQ(cfg.verifyPass, expected);
    ASSERT_EQ(cfg.verifyFail, 0u);
  } else {
    ASSERT_EQ(cfg.verifyPass, 0u);
    ASSERT_EQ(cfg.verifyFail, 0u);
  }

  return 0;
}

int main() {
  int failures = 0;
  failures += run_emulate_case("emulate-polling", 12, 1, 0, false);
  failures += run_emulate_case("emulate-polling-verify", 8, 2, 0, true);
  failures += run_emulate_case("emulate-doorbell", 16, 1, 64, false);
  failures += run_emulate_case("emulate-doorbell-verify", 10, 4, 64, true);

  if (failures == 0) {
    printf("All test-ep emulate tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate test(s) failed.\n", failures);
  return 1;
}
