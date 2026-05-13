/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Additional CPU-only tests for rdma_ep::validateConfig().
 */

#include <cstdio>
#include <string>

#include <hip/hip_runtime.h>

#include "rdma-ep.h"
#include "xio-test-assert.h"

int test_sq_depth_zero() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.sqDepth = 0;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_transfer_size_zero() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.transferSize = 0;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_batch_size_ge_sq_depth() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.sqDepth = 8;
  cfg.batchSize = 8;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_batch_gt_one_requires_loopback() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.loopback = false;
  cfg.batchSize = 2;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_num_queues_gt_one_requires_loopback() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.loopback = false;
  cfg.numQueues = 2;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_server_and_client_exclusive() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.isServer = true;
  cfg.isClient = true;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_no_loopback_requires_role() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.loopback = false;
  cfg.isServer = false;
  cfg.isClient = false;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_client_requires_server_host() {
  xio::rdma_ep::RdmaEpConfig cfg;
  cfg.providerStr = "bnxt";
  cfg.loopback = false;
  cfg.isClient = true;
  cfg.serverHost.clear();
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int main() {
  int failures = 0;
  failures += test_sq_depth_zero();
  failures += test_transfer_size_zero();
  failures += test_batch_size_ge_sq_depth();
  failures += test_batch_gt_one_requires_loopback();
  failures += test_num_queues_gt_one_requires_loopback();
  failures += test_server_and_client_exclusive();
  failures += test_no_loopback_requires_role();
  failures += test_client_requires_server_host();

  if (failures == 0) {
    printf("All rdma validate-extra tests passed.\n");
    return 0;
  }
  printf("%d rdma validate-extra test(s) failed.\n", failures);
  return 1;
}
