/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for sdma-ep configuration defaults, host-side validateConfig(),
 * and the public constants from sdma-ep.h. These are CPU-only and do not
 * exercise any SDMA hardware path -- the device-side packet builders are
 * __device__ only and live in their own system tests.
 */

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>

#include <hip/hip_runtime.h>

#include "sdma-ep.h"
#include "xio-test-assert.h"

using xio::sdma_ep::SdmaEpConfig;

int test_config_defaults() {
  SdmaEpConfig cfg;
  ASSERT_TRUE(cfg.testType.empty());
  ASSERT_TRUE(!cfg.useHostDst);
  ASSERT_TRUE(!cfg.verifyData);
  ASSERT_TRUE(!cfg.useCounter);
  ASSERT_TRUE(!cfg.useFlush);
  ASSERT_EQ(cfg.srcDeviceId, -1);
  ASSERT_EQ(cfg.dstDeviceId, -1);
  ASSERT_EQ(cfg.transferSize, static_cast<size_t>(4096));
  ASSERT_EQ(cfg.iterations, 128u);
  return 0;
}

int test_constants() {
  ASSERT_EQ(xio::sdma_ep::SDMA_QUEUE_SIZE, static_cast<uint64_t>(1024 * 1024));
  ASSERT_EQ(xio::sdma_ep::MAX_RETRIES, 1 << 30);
  ASSERT_TRUE(!xio::sdma_ep::BREAK_ON_RETRIES);
  return 0;
}

int test_connection_info_layout() {
  xio::sdma_ep::SdmaConnectionInfo info{};
  info.srcDeviceId = 0;
  info.dstDeviceId = 1;
  info.engineId = 7;
  ASSERT_EQ(info.srcDeviceId, 0);
  ASSERT_EQ(info.dstDeviceId, 1);
  ASSERT_EQ(info.engineId, 7u);
  return 0;
}

int test_queue_info_layout() {
  xio::sdma_ep::SdmaQueueInfo info{};
  info.deviceHandle = nullptr;
  info.srcDeviceId = 2;
  info.dstDeviceId = 3;
  info.channelIdx = 5;
  ASSERT_TRUE(info.deviceHandle == nullptr);
  ASSERT_EQ(info.srcDeviceId, 2);
  ASSERT_EQ(info.dstDeviceId, 3);
  ASSERT_EQ(info.channelIdx, 5);
  return 0;
}

int test_validate_null_is_silent() {
  /* validateConfig(nullptr) returns an empty string by contract: any later
   * code that dereferences config would crash before this validator runs. */
  std::string err = xio::sdma_ep::validateConfig(nullptr);
  ASSERT_TRUE(err.empty());
  return 0;
}

int test_validate_missing_subcommand() {
  SdmaEpConfig cfg;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  ASSERT_TRUE(err.find("subcommand") != std::string::npos ||
              err.find("p2p") != std::string::npos);
  return 0;
}

int test_validate_counter_and_flush_conflict() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.useCounter = true;
  cfg.useFlush = true;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  ASSERT_TRUE(err.find("--use-counter") != std::string::npos);
  ASSERT_TRUE(err.find("--use-flush") != std::string::npos);
  return 0;
}

int test_validate_transfer_size_zero() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.transferSize = 0;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  ASSERT_TRUE(err.find("transfer-size") != std::string::npos);
  return 0;
}

int test_validate_transfer_size_not_multiple_of_four() {
  SdmaEpConfig cfg;
  cfg.testType = "ping-pong";
  cfg.transferSize = 6;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  ASSERT_TRUE(err.find("multiple of 4") != std::string::npos);
  return 0;
}

int test_validate_good_p2p() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.transferSize = 4096;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.empty());
  return 0;
}

int test_validate_good_ping_pong_counter_only() {
  SdmaEpConfig cfg;
  cfg.testType = "ping-pong";
  cfg.useCounter = true;
  cfg.useFlush = false;
  cfg.transferSize = 4;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.empty());
  return 0;
}

int test_validate_good_buffer_reuse_flush_only() {
  SdmaEpConfig cfg;
  cfg.testType = "buffer-reuse";
  cfg.useFlush = true;
  cfg.useCounter = false;
  cfg.transferSize = 65536;
  std::string err = xio::sdma_ep::validateConfig(&cfg);
  ASSERT_TRUE(err.empty());
  return 0;
}

int test_getIterations_returns_fixed_value() {
  /* sdma-ep currently hard-codes 128 iterations from getIterations. Lock
   * that into a test so any change to the contract becomes visible. */
  SdmaEpConfig cfg;
  cfg.iterations = 999;
  unsigned iters = xio::sdma_ep::getIterations(&cfg);
  ASSERT_EQ(iters, 128u);
  iters = xio::sdma_ep::getIterations(nullptr);
  ASSERT_EQ(iters, 128u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_config_defaults();
  failures += test_constants();
  failures += test_connection_info_layout();
  failures += test_queue_info_layout();
  failures += test_validate_null_is_silent();
  failures += test_validate_missing_subcommand();
  failures += test_validate_counter_and_flush_conflict();
  failures += test_validate_transfer_size_zero();
  failures += test_validate_transfer_size_not_multiple_of_four();
  failures += test_validate_good_p2p();
  failures += test_validate_good_ping_pong_counter_only();
  failures += test_validate_good_buffer_reuse_flush_only();
  failures += test_getIterations_returns_fixed_value();

  if (failures == 0) {
    printf("All sdma-ep config tests passed.\n");
    return 0;
  }
  printf("%d sdma-ep config test(s) failed.\n", failures);
  return 1;
}
