/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for sdma-ep configuration helpers.
 */

#include <cstdio>
#include <string>

#include "sdma-ep.h"
#include "xio-test-assert.h"

using namespace xio::sdma_ep;

int test_config_defaults() {
  SdmaEpConfig cfg;
  ASSERT_TRUE(cfg.testType.empty());
  ASSERT_TRUE(!cfg.useHostDst);
  ASSERT_TRUE(!cfg.verifyData);
  ASSERT_TRUE(!cfg.useCounter);
  ASSERT_TRUE(!cfg.useFlush);
  ASSERT_EQ(cfg.srcDeviceId, -1);
  ASSERT_EQ(cfg.dstDeviceId, -1);
  ASSERT_EQ(cfg.transferSize, 4096u);
  ASSERT_EQ(cfg.iterations, 128u);
  return 0;
}

int test_validate_missing_subcommand() {
  SdmaEpConfig cfg;
  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(err.find("Missing test subcommand") != std::string::npos);
  return 0;
}

int test_validate_counter_flush_conflict() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.useCounter = true;
  cfg.useFlush = true;
  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(err.find("Cannot use both --use-counter and --use-flush") !=
              std::string::npos);
  return 0;
}

int test_validate_transfer_size_zero() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.transferSize = 0;
  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(err.find("transfer-size must be > 0") != std::string::npos);
  return 0;
}

int test_validate_transfer_size_alignment() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.transferSize = 258;
  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(err.find("transfer-size must be a multiple of 4") !=
              std::string::npos);
  return 0;
}

int test_validate_success() {
  SdmaEpConfig cfg;
  cfg.testType = "ping-pong";
  cfg.transferSize = 8192;
  cfg.useCounter = true;
  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(err.empty());
  return 0;
}

int test_get_iterations_constant() {
  SdmaEpConfig cfg;
  cfg.iterations = 4096;
  ASSERT_EQ(getIterations(&cfg), 128u);
  ASSERT_EQ(getIterations(nullptr), 128u);
  return 0;
}

int test_destroy_queue_clears_handle() {
  SdmaQueueInfo info{};
  info.deviceHandle = reinterpret_cast<void*>(0x1234);
  destroyQueue(&info);
  ASSERT_EQ(info.deviceHandle, nullptr);
  destroyQueue(nullptr);
  return 0;
}

int test_shutdown_disables_connection_creation() {
  shutdownEndpoint();
  SdmaConnectionInfo info{};
  int rc = createConnection(0, 1, &info);
  ASSERT_EQ(rc, -1);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_config_defaults();
  failures += test_validate_missing_subcommand();
  failures += test_validate_counter_flush_conflict();
  failures += test_validate_transfer_size_zero();
  failures += test_validate_transfer_size_alignment();
  failures += test_validate_success();
  failures += test_get_iterations_constant();
  failures += test_destroy_queue_clears_handle();
  failures += test_shutdown_disables_connection_creation();

  if (failures == 0) {
    printf("All sdma-ep config tests passed.\n");
    return 0;
  }
  printf("%d sdma-ep config test(s) failed.\n", failures);
  return 1;
}
