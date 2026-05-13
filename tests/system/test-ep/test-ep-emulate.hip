/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * System-level test for test-ep in emulate mode.
 *
 * Validates SQE/CQE round-trips through the library API (the same endpoint
 * logic as ``xio-tester test-ep --emulate``) for polling mode, doorbell mode,
 * and multi-thread polling. CLI coverage for ``xio-tester`` is registered
 * separately as CTest entries in ``CMakeLists.txt``.
 */

#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio.h"

namespace {

/** Match TestEndpoint::getSubmissionQueueLength sizing rules. */
size_t submission_slots(unsigned num_threads, unsigned doorbell) {
  if (doorbell > 0) {
    return doorbell;
  }
  return (num_threads > 1) ? num_threads : 1;
}

int run_emulate(unsigned iterations, unsigned num_threads, unsigned doorbell) {
  xio::XioEndpointConfig cfg(iterations, num_threads);

  xio::test_ep::TestEpConfig epCfg;
  epCfg.emulate = true;
  epCfg.enableCpuThreads = true;
  epCfg.iterations = iterations;
  epCfg.doorbell = doorbell;
  cfg.endpointConfig = &epCfg;

  const size_t slots = submission_slots(num_threads, doorbell);
  const size_t sqSize = slots * sizeof(xio::test_ep::test_sqe);
  const size_t cqSize = slots * sizeof(xio::test_ep::test_cqe);

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

int test_emulate_polling_basic() {
  return run_emulate(10, 1, 0);
}

int test_emulate_doorbell() {
  return run_emulate(12, 1, 64);
}

int test_emulate_multi_thread_polling() {
  return run_emulate(8, 4, 0);
}

int main() {
  int failures = 0;
  failures += test_emulate_polling_basic();
  failures += test_emulate_doorbell();
  failures += test_emulate_multi_thread_polling();

  if (failures == 0) {
    printf("All test-ep emulate tests passed.\n");
    return 0;
  }
  printf("%d test-ep emulate test(s) failed.\n", failures);
  return 1;
}
