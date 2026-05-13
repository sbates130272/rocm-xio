/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for shared xio core types and constants.
 */

#include <climits>
#include <cstddef>
#include <cstdint>
#include <cstdio>

#include "xio-endpoint-core.h"
#include "xio-test-assert.h"
#include "xio.h"

int test_memory_mode_flags() {
  ASSERT_EQ(XIO_MEM_MODE_SQ_DEVICE, 0x1);
  ASSERT_EQ(XIO_MEM_MODE_CQ_DEVICE, 0x2);
  ASSERT_EQ(XIO_MEM_MODE_DOORBELL_DEVICE, 0x4);
  ASSERT_EQ(XIO_MEM_MODE_DATA_DEVICE, 0x8);
  return 0;
}

int test_device_memory_flags() {
  ASSERT_EQ(XIO_DEVICE_MEM_FINE_GRAINED, 0x0);
  ASSERT_EQ(XIO_DEVICE_MEM_COARSE_GRAINED, 0x1);
  ASSERT_EQ(XIO_DEVICE_MEM_UNCACHED, 0x2);
  ASSERT_EQ(XIO_DEVICE_MEM_VMEM, 0x4);
  ASSERT_EQ(XIO_DEVICE_MEM_HIP, 0x8);
  return 0;
}

int test_host_memory_flags() {
  ASSERT_EQ(XIO_HOST_MEM_MAPPED, 0x0);
  ASSERT_EQ(XIO_HOST_MEM_COHERENT, 0x1);
  ASSERT_EQ(XIO_HOST_MEM_PINNED, 0x2);
  ASSERT_EQ(XIO_HOST_MEM_PLAIN, 0x4);
  ASSERT_EQ(XIO_HOST_MEM_DEFAULT, 0x8);
  return 0;
}

int test_timing_stats_defaults() {
  xio::XioTimingStats stats;
  ASSERT_EQ(stats.minDuration, ULLONG_MAX);
  ASSERT_EQ(stats.maxDuration, 0ull);
  ASSERT_EQ(stats.sumDuration, 0ull);
  ASSERT_EQ(stats.count, 0ull);
  return 0;
}

int test_endpoint_config_defaults() {
  xio::XioEndpointConfig cfg;
  ASSERT_EQ(cfg.iterations, 128u);
  ASSERT_EQ(cfg.numThreads, 1u);
  ASSERT_EQ(cfg.delayNs, 0ll);
  ASSERT_EQ(cfg.memoryMode, 0u);
  ASSERT_TRUE(!cfg.verbose);
  ASSERT_TRUE(!cfg.pciMmioBridge);
  ASSERT_EQ(cfg.startTimes, nullptr);
  ASSERT_EQ(cfg.endTimes, nullptr);
  ASSERT_EQ(cfg.timingStats, nullptr);
  ASSERT_EQ(cfg.substepStats, nullptr);
  ASSERT_EQ(cfg.submissionQueue, nullptr);
  ASSERT_EQ(cfg.completionQueue, nullptr);
  ASSERT_EQ(cfg.stopRequested, nullptr);
  ASSERT_EQ(cfg.endpointConfig, nullptr);
  ASSERT_EQ(cfg.verifyPass, 0u);
  ASSERT_EQ(cfg.verifyFail, 0u);
  return 0;
}

int test_endpoint_config_ctor() {
  xio::XioEndpointConfig cfg(17, 3);
  ASSERT_EQ(cfg.iterations, 17u);
  ASSERT_EQ(cfg.numThreads, 3u);
  return 0;
}

int test_mmio_bridge_layout() {
  ASSERT_EQ(sizeof(xio::pci_mmio_bridge_ring_meta), 16u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_ring_meta, producer_idx), 0u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_ring_meta, consumer_idx), 4u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_ring_meta, queue_depth), 8u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_ring_meta, reserved), 12u);

  ASSERT_EQ(sizeof(xio::pci_mmio_bridge_command), 24u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, target_bdf), 0u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, target_bar), 2u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, offset), 4u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, value), 8u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, command), 16u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, size), 17u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, status), 18u);
  ASSERT_EQ(offsetof(xio::pci_mmio_bridge_command, sequence), 20u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_memory_mode_flags();
  failures += test_device_memory_flags();
  failures += test_host_memory_flags();
  failures += test_timing_stats_defaults();
  failures += test_endpoint_config_defaults();
  failures += test_endpoint_config_ctor();
  failures += test_mmio_bridge_layout();

  if (failures == 0) {
    printf("All xio core config tests passed.\n");
    return 0;
  }
  printf("%d xio core config test(s) failed.\n", failures);
  return 1;
}
