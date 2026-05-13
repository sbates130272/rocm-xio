/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for rdma-common backend configuration helpers.
 */

#include <cstdio>

#include "gda-backend.hpp"
#include "ibv-core.hpp"
#include "rdma-common.h"
#include "xio-test-assert.h"
#include "xio.h"

using namespace xio::rdma_ep;

int test_make_backend_config_device_queue() {
  xio::XioEndpointConfig config;
  config.memoryMode = XIO_MEM_MODE_SQ_DEVICE;
  config.pciMmioBridge = true;

  RdmaEpConfig rdmaConfig;
  rdmaConfig.provider = Provider::IONIC;
  rdmaConfig.gpuDeviceId = 2;
  rdmaConfig.sqDepth = 512;
  rdmaConfig.cqDepth = 1024;
  rdmaConfig.inlineThreshold = 64;
  rdmaConfig.pcieRelaxedOrdering = true;
  rdmaConfig.trafficClass = 7;
  rdmaConfig.deviceName = "rocm-rdma-ionic0";

  BackendConfig backend = make_backend_config(config, rdmaConfig, true);
  ASSERT_EQ(backend.provider, Provider::IONIC);
  ASSERT_EQ(backend.gpu_device_id, 2);
  ASSERT_EQ(backend.sq_depth, 512u);
  ASSERT_EQ(backend.cq_depth, 1024u);
  ASSERT_EQ(backend.inline_threshold, 64u);
  ASSERT_TRUE(backend.pcie_relaxed_ordering);
  ASSERT_EQ(backend.traffic_class, 7);
  ASSERT_TRUE(backend.loopback);
  ASSERT_EQ(backend.queue_mem, QueueMemMode::DEVICE_VRAM);
  ASSERT_TRUE(backend.pci_mmio_bridge);
  ASSERT_STREQ(backend.hca_list, "rocm-rdma-ionic0");
  return 0;
}

int test_make_backend_config_host_queue() {
  xio::XioEndpointConfig config;
  config.memoryMode = 0;
  config.pciMmioBridge = false;

  RdmaEpConfig rdmaConfig;
  rdmaConfig.provider = Provider::BNXT;
  rdmaConfig.deviceName.clear();

  BackendConfig backend = make_backend_config(config, rdmaConfig, false);
  ASSERT_EQ(backend.provider, Provider::BNXT);
  ASSERT_TRUE(!backend.loopback);
  ASSERT_EQ(backend.queue_mem, QueueMemMode::HOST_COHERENT);
  ASSERT_TRUE(!backend.pci_mmio_bridge);
  ASSERT_EQ(backend.hca_list, nullptr);
  return 0;
}

int test_fill_rc_qp_init_attr() {
  struct ibv_qp_init_attr_ex attr = {};
  struct ibv_pd pd = {};
  struct ibv_cq cq = {};

  fill_rc_qp_init_attr(&attr, &pd, &cq, 128, 64, 8, 32);

  ASSERT_EQ(attr.send_cq, &cq);
  ASSERT_EQ(attr.recv_cq, &cq);
  ASSERT_EQ(attr.srq, nullptr);
  ASSERT_EQ(attr.cap.max_send_wr, 128u);
  ASSERT_EQ(attr.cap.max_recv_wr, 64u);
  ASSERT_EQ(attr.cap.max_send_sge, 1u);
  ASSERT_EQ(attr.cap.max_recv_sge, 8u);
  ASSERT_EQ(attr.cap.max_inline_data, 32u);
  ASSERT_EQ(attr.qp_type, IBV_QPT_RC);
  ASSERT_EQ(attr.sq_sig_all, 0);
  ASSERT_EQ(attr.comp_mask, IBV_QP_INIT_ATTR_PD);
  ASSERT_EQ(attr.pd, &pd);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_make_backend_config_device_queue();
  failures += test_make_backend_config_host_queue();
  failures += test_fill_rc_qp_init_attr();

  if (failures == 0) {
    printf("All rdma backend config tests passed.\n");
    return 0;
  }
  printf("%d rdma backend config test(s) failed.\n", failures);
  return 1;
}
