/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for rdma-ep vendor-ops.hpp constants and descriptor layout.
 */

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "vendor-ops.hpp"
#include "xio-test-assert.h"

int test_pci_vendor_ids() {
  ASSERT_EQ(xio::rdma_ep::VENDOR_ID_BROADCOM, 0x14E4u);
  ASSERT_EQ(xio::rdma_ep::VENDOR_ID_MELLANOX, 0x02C9u);
  ASSERT_EQ(xio::rdma_ep::VENDOR_ID_PENSANDO, 0x1DD8u);
  ASSERT_EQ(xio::rdma_ep::VENDOR_ID_AMD, 0x1022u);
  return 0;
}

int test_wave_and_lock_constants() {
  ASSERT_EQ(xio::rdma_ep::WF_SIZE, 64u);
  ASSERT_EQ(xio::rdma_ep::SPIN_LOCK_UNLOCKED, 0u);
  return 0;
}

int test_rma_descriptor_layout() {
  ASSERT_EQ(offsetof(xio::rdma_ep::RmaDescriptor, local_addr), 0u);
  ASSERT_EQ(offsetof(xio::rdma_ep::RmaDescriptor, remote_addr), sizeof(uintptr_t));
  ASSERT_TRUE(sizeof(xio::rdma_ep::RmaDescriptor) >= 32u);
  return 0;
}

int test_amo_descriptor_layout() {
  ASSERT_EQ(offsetof(xio::rdma_ep::AmoDescriptor, remote_addr), 0u);
  ASSERT_TRUE(sizeof(xio::rdma_ep::AmoDescriptor) >= 32u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_pci_vendor_ids();
  failures += test_wave_and_lock_constants();
  failures += test_rma_descriptor_layout();
  failures += test_amo_descriptor_layout();
  if (failures == 0) {
    printf("All rdma vendor-ops constant tests passed.\n");
    return 0;
  }
  printf("%d rdma vendor-ops test(s) failed.\n", failures);
  return 1;
}
