/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for memory-mode and related constants in xio.h.
 */

#include <cstdio>

#include <hip/hip_runtime.h>

#include "xio-test-assert.h"
#include "xio.h"

int test_mem_mode_flags_distinct() {
  ASSERT_NE(XIO_MEM_MODE_SQ_DEVICE, XIO_MEM_MODE_CQ_DEVICE);
  ASSERT_NE(XIO_MEM_MODE_SQ_DEVICE, XIO_MEM_MODE_DOORBELL_DEVICE);
  ASSERT_NE(XIO_MEM_MODE_SQ_DEVICE, XIO_MEM_MODE_DATA_DEVICE);
  ASSERT_NE(XIO_MEM_MODE_CQ_DEVICE, XIO_MEM_MODE_DOORBELL_DEVICE);
  return 0;
}

int test_device_mem_flags_distinct() {
  ASSERT_NE(XIO_DEVICE_MEM_FINE_GRAINED, XIO_DEVICE_MEM_COARSE_GRAINED);
  ASSERT_NE(XIO_DEVICE_MEM_COARSE_GRAINED, XIO_DEVICE_MEM_UNCACHED);
  ASSERT_NE(XIO_DEVICE_MEM_UNCACHED, XIO_DEVICE_MEM_VMEM);
  ASSERT_NE(XIO_DEVICE_MEM_VMEM, XIO_DEVICE_MEM_HIP);
  return 0;
}

int test_host_mem_flags_distinct() {
  ASSERT_NE(XIO_HOST_MEM_MAPPED, XIO_HOST_MEM_COHERENT);
  ASSERT_NE(XIO_HOST_MEM_COHERENT, XIO_HOST_MEM_PINNED);
  ASSERT_NE(XIO_HOST_MEM_PINNED, XIO_HOST_MEM_PLAIN);
  ASSERT_NE(XIO_HOST_MEM_PLAIN, XIO_HOST_MEM_DEFAULT);
  return 0;
}

int test_pci_mmio_bridge_constants() {
  ASSERT_NE(PCI_MMIO_BRIDGE_CMD_NOP, PCI_MMIO_BRIDGE_CMD_WRITE);
  ASSERT_NE(PCI_MMIO_BRIDGE_CMD_WRITE, PCI_MMIO_BRIDGE_CMD_READ);
  ASSERT_NE(PCI_MMIO_BRIDGE_STATUS_PENDING, PCI_MMIO_BRIDGE_STATUS_COMPLETE);
  ASSERT_NE(PCI_MMIO_BRIDGE_STATUS_COMPLETE, PCI_MMIO_BRIDGE_STATUS_ERROR);
  return 0;
}

int test_rocm_xio_device_path() {
  ASSERT_STREQ(ROCM_XIO_DEVICE_PATH, "/dev/rocm-xio");
  return 0;
}

int main() {
  int failures = 0;
  failures += test_mem_mode_flags_distinct();
  failures += test_device_mem_flags_distinct();
  failures += test_host_mem_flags_distinct();
  failures += test_pci_mmio_bridge_constants();
  failures += test_rocm_xio_device_path();

  if (failures == 0) {
    printf("All xio memory-constant tests passed.\n");
    return 0;
  }
  printf("%d xio memory-constant test(s) failed.\n", failures);
  return 1;
}
