/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 */

/* System-level tests for test-ep in emulate mode.
 *
 * Covers polling mode, doorbell mode, multi-thread polling, and LFSR
 * verification (CPU emulation path). These exercise the same library entry
 * point used by `xio-tester test-ep --emulate` with a minimal configuration.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio.h"

namespace {

size_t submission_queue_entries(unsigned threads, unsigned doorbell) {
  if (doorbell > 0) {
    return doorbell;
  }
  return (threads > 1) ? threads : 1;
}

hipError_t alloc_pair(size_t sqBytes, size_t cqBytes, void** sq, void** cq) {
  hipError_t sq_err =
    xio::allocHostMemory(sqBytes, sq, "emulate SQ", XIO_HOST_MEM_PLAIN);
  hipError_t cq_err =
    xio::allocHostMemory(cqBytes, cq, "emulate CQ", XIO_HOST_MEM_PLAIN);
  if (sq_err != hipSuccess || cq_err != hipSuccess) {
    xio::freeHostMemory(*sq, XIO_HOST_MEM_PLAIN);
    xio::freeHostMemory(*cq, XIO_HOST_MEM_PLAIN);
    *sq = nullptr;
    *cq = nullptr;
    return hipErrorMemoryAllocation;
  }
  return hipSuccess;
}

int run_emulate_scenario(unsigned iterations, unsigned threads,
                         unsigned doorbell, bool verify, uint32_t seed) {
  xio::XioEndpointConfig cfg(iterations, threads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = iterations;
  epCfg.doorbell = doorbell;
  epCfg.verify = verify;
  epCfg.seed = seed;
  cfg.endpointConfig = &epCfg;

  const size_t qEntries = submission_queue_entries(threads, doorbell);
  const size_t sqBytes = qEntries * sizeof(xio::test_ep::test_sqe);
  const size_t cqBytes = qEntries * sizeof(xio::test_ep::test_cqe);

  void *sq = nullptr, *cq = nullptr;
  if (alloc_pair(sqBytes, cqBytes, &sq, &cq) != hipSuccess) {
    fprintf(stderr, "Allocation failed\n");
    return 1;
  }

  cfg.submissionQueue = sq;
  cfg.completionQueue = cq;

  hipError_t err = xio::test_ep::run(&cfg);

  xio::freeHostMemory(sq, XIO_HOST_MEM_PLAIN);
  xio::freeHostMemory(cq, XIO_HOST_MEM_PLAIN);

  if (err != hipSuccess) {
    fprintf(stderr, "test-ep emulate run failed: %d\n", static_cast<int>(err));
    return 1;
  }

  if (verify && doorbell == 0) {
    const uint32_t expected =
      static_cast<uint32_t>(iterations) * static_cast<uint32_t>(threads);
    if (cfg.verifyFail != 0) {
      fprintf(stderr, "verifyFail=%u (expected 0)\n", cfg.verifyFail);
      return 1;
    }
    if (cfg.verifyPass != expected) {
      fprintf(stderr, "verifyPass=%u (expected %u)\n", cfg.verifyPass,
              expected);
      return 1;
    }
  }

  return 0;
}

} // namespace

int test_emulate_roundtrip() {
  return run_emulate_scenario(10, 1, 0, false, 1);
}

int test_emulate_doorbell() {
  const unsigned kThreads = 2;
  const unsigned kDoorbell = 64;
  const unsigned kIter = 24;
  if (kThreads > kDoorbell) {
    fprintf(stderr, "invalid doorbell test dimensions\n");
    return 1;
  }
  return run_emulate_scenario(kIter, kThreads, kDoorbell, false, 1);
}

int test_emulate_multithread_poll() {
  return run_emulate_scenario(8, 4, 0, false, 1);
}

int test_emulate_verify_single_thread() {
  return run_emulate_scenario(20, 1, 0, true, 42);
}

int test_emulate_verify_multi_thread() {
  return run_emulate_scenario(15, 2, 0, true, 7);
}

int main() {
  int failures = 0;
  failures += test_emulate_roundtrip();
  failures += test_emulate_doorbell();
  failures += test_emulate_multithread_poll();
  failures += test_emulate_verify_single_thread();
  failures += test_emulate_verify_multi_thread();

  if (failures == 0) {
    printf("All test-ep emulate tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate test(s) failed.\n", failures);
  return 1;
}
