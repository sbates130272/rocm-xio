/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for nvme-ep.h public constants and doorbell parameters.
 */

#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "nvme-ep.h"
#include "xio-test-assert.h"

int test_nvme_admin_and_log_sizes() {
  ASSERT_EQ(xio::nvme_ep::nvmeAdminRespSize, 4096u);
  ASSERT_EQ(xio::nvme_ep::nvmeLogPageSize, 512u);
  return 0;
}

int test_nvme_doorbell_layout_constants() {
  ASSERT_EQ(xio::nvme_ep::doorbellBase, 0x1000u);
  ASSERT_EQ(xio::nvme_ep::doorBellStride, 4u);
  return 0;
}

int test_nvme_poll_limits() {
  ASSERT_GT(xio::nvme_ep::NVME_EP_MAX_POLLS, xio::nvme_ep::NVME_EP_MAX_POLLS_BEFORE_BACKOFF);
  return 0;
}

int main() {
  test_nvme_admin_and_log_sizes();
  test_nvme_doorbell_layout_constants();
  test_nvme_poll_limits();
  printf("test-nvme-constants: all tests passed\n");
  return 0;
}
