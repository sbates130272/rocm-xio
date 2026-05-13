/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for stable nvme-ep constants and small POD layout checks.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "nvme-ep.h"
#include "xio-test-assert.h"

int test_nvme_ep_macro_constants() {
  ASSERT_EQ(NVME_EP_MAX_POLLS_BEFORE_BACKOFF, 1000u);
  ASSERT_TRUE(NVME_EP_MAX_POLLS > NVME_EP_MAX_POLLS_BEFORE_BACKOFF);
  return 0;
}

int test_nvme_ep_constexpr_doorbell() {
  ASSERT_EQ(xio::nvme_ep::doorbellBase, 0x1000u);
  ASSERT_EQ(xio::nvme_ep::doorBellStride, 4u);
  ASSERT_EQ(xio::nvme_ep::nvmeAdminRespSize, 4096u);
  ASSERT_EQ(xio::nvme_ep::nvmeLogPageSize, 512u);
  return 0;
}

int test_nvme_io_params_size() {
  ASSERT_TRUE(sizeof(xio::nvme_ep::nvmeIoParams) >= 40u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_nvme_ep_macro_constants();
  failures += test_nvme_ep_constexpr_doorbell();
  failures += test_nvme_io_params_size();
  if (failures == 0) {
    printf("All nvme-ep constant tests passed.\n");
    return 0;
  }
  printf("%d nvme-ep constant test(s) failed.\n", failures);
  return 1;
}
