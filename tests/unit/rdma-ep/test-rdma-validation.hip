/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for rdma-ep host-side config validation paths.
 */

#include <cstdio>
#include <string>

#include "rdma-ep.h"
#include "xio-test-assert.h"

using xio::rdma_ep::RdmaEpConfig;

int test_validate_null_config() {
  std::string err = xio::rdma_ep::validateConfig(nullptr);
  ASSERT_TRUE(!err.empty());
  return 0;
}

int test_validate_zero_sq_depth() {
  RdmaEpConfig cfg;
  cfg.sqDepth = 0;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.find("SQ depth") != std::string::npos);
  return 0;
}

int test_validate_zero_transfer_size() {
  RdmaEpConfig cfg;
  cfg.transferSize = 0;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.find("Transfer size") != std::string::npos);
  return 0;
}

int test_validate_batch_requires_loopback() {
  RdmaEpConfig cfg;
  cfg.loopback = false;
  cfg.batchSize = 2;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.find("requires loopback") != std::string::npos);
  return 0;
}

int test_validate_num_queues_requires_loopback() {
  RdmaEpConfig cfg;
  cfg.loopback = false;
  cfg.numQueues = 2;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.find("requires loopback") != std::string::npos);
  return 0;
}

int test_validate_server_client_mutually_exclusive() {
  RdmaEpConfig cfg;
  cfg.isServer = true;
  cfg.isClient = true;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.find("mutually exclusive") != std::string::npos);
  return 0;
}

int test_validate_client_requires_host() {
  RdmaEpConfig cfg;
  cfg.isClient = true;
  cfg.serverHost = "";
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.find("--client requires --server-host") != std::string::npos);
  return 0;
}

int test_validate_ping_pong_size_constraints() {
  RdmaEpConfig small;
  small.isServer = true;
  small.ppSize = 8;
  std::string err_small = xio::rdma_ep::validateConfig(&small);
  ASSERT_TRUE(err_small.find(">= 16") != std::string::npos);

  RdmaEpConfig align;
  align.isServer = true;
  align.ppSize = 22;
  std::string err_align = xio::rdma_ep::validateConfig(&align);
  ASSERT_TRUE(err_align.find("multiple of 8") != std::string::npos);
  return 0;
}

int test_validate_infinite_mode_sets_iterations() {
  RdmaEpConfig cfg;
  cfg.infiniteMode = true;
  cfg.iterations = 999;
  std::string err = xio::rdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.empty());
  ASSERT_EQ(cfg.iterations, 0u);
  return 0;
}

int test_get_iterations() {
  RdmaEpConfig cfg;
  cfg.iterations = 17;
  cfg.infiniteMode = false;
  ASSERT_EQ(xio::rdma_ep::getIterations(&cfg), 17u);

  cfg.infiniteMode = true;
  ASSERT_EQ(xio::rdma_ep::getIterations(&cfg), 0u);

  ASSERT_EQ(xio::rdma_ep::getIterations(nullptr), 128u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_validate_null_config();
  failures += test_validate_zero_sq_depth();
  failures += test_validate_zero_transfer_size();
  failures += test_validate_batch_requires_loopback();
  failures += test_validate_num_queues_requires_loopback();
  failures += test_validate_server_client_mutually_exclusive();
  failures += test_validate_client_requires_host();
  failures += test_validate_ping_pong_size_constraints();
  failures += test_validate_infinite_mode_sets_iterations();
  failures += test_get_iterations();

  if (failures == 0) {
    printf("All rdma validation tests passed.\n");
    return 0;
  }
  printf("%d rdma validation test(s) failed.\n", failures);
  return 1;
}
