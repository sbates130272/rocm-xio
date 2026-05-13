/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * System-level tests for test-ep in emulate mode.
 *
 * Covers polling mode, doorbell mode, and multi-threaded polling. Each case
 * exercises the same host-side paths as ``xio-tester test-ep --emulate`` but
 * through the library API with a minimal configuration.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"
#include "xio.h"

namespace {

unsigned submission_queue_slots(unsigned numThreads, unsigned doorbell) {
  if (doorbell > 0) {
    return doorbell;
  }
  return (numThreads > 1) ? numThreads : 1;
}

int run_emulate(unsigned iterations, unsigned numThreads, unsigned doorbell) {
  xio::XioEndpointConfig cfg(iterations, numThreads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = iterations;
  epCfg.doorbell = doorbell;
  cfg.endpointConfig = &epCfg;

  const unsigned slots = submission_queue_slots(numThreads, doorbell);
  const size_t sqSize =
    static_cast<size_t>(slots) * sizeof(xio::test_ep::test_sqe);
  const size_t cqSize =
    static_cast<size_t>(slots) * sizeof(xio::test_ep::test_cqe);

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
    fprintf(stderr, "test-ep emulate run failed: %d\n", static_cast<int>(err));
    return 1;
  }
  return 0;
}

} // namespace

int test_emulate_roundtrip_polling() {
  return run_emulate(10, 1, 0);
}

int test_emulate_roundtrip_doorbell() {
  return run_emulate(24, 2, 16);
}

int test_emulate_multi_thread_polling() {
  return run_emulate(8, 4, 0);
}

int main() {
  int failures = 0;
  failures += test_emulate_roundtrip_polling();
  failures += test_emulate_roundtrip_doorbell();
  failures += test_emulate_multi_thread_polling();

  if (failures == 0) {
    printf("All test-ep emulate tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate test(s) failed.\n", failures);
  return 1;
}
