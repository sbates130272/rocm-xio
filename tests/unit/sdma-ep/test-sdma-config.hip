/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for sdma-ep configuration validation.
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
  ASSERT_EQ(cfg.transferSize, static_cast<size_t>(4096));
  ASSERT_EQ(cfg.iterations, 128u);
  return 0;
}

int test_validate_config_allows_null() {
  ASSERT_TRUE(validateConfig(nullptr).empty());
  return 0;
}

int test_validate_config_requires_test_type() {
  SdmaEpConfig cfg;
  std::string error = validateConfig(&cfg);
  ASSERT_TRUE(!error.empty());
  ASSERT_TRUE(error.find("Missing test subcommand") != std::string::npos);
  return 0;
}

int test_validate_config_rejects_counter_with_flush() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.useCounter = true;
  cfg.useFlush = true;

  std::string error = validateConfig(&cfg);
  ASSERT_TRUE(!error.empty());
  ASSERT_TRUE(error.find("Cannot use both") != std::string::npos);
  return 0;
}

int test_validate_config_rejects_zero_transfer_size() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.transferSize = 0;

  ASSERT_STREQ(validateConfig(&cfg).c_str(), "transfer-size must be > 0");
  return 0;
}

int test_validate_config_rejects_unaligned_transfer_size() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";
  cfg.transferSize = 1025;

  std::string error = validateConfig(&cfg);
  ASSERT_TRUE(!error.empty());
  ASSERT_TRUE(error.find("multiple of 4") != std::string::npos);
  return 0;
}

int test_validate_config_accepts_valid_modes() {
  const char* modes[] = {"p2p", "ping-pong", "buffer-reuse"};
  for (const char* mode : modes) {
    SdmaEpConfig cfg;
    cfg.testType = mode;
    cfg.transferSize = 4096;
    ASSERT_TRUE(validateConfig(&cfg).empty());
  }
  return 0;
}

int test_get_iterations_current_default() {
  SdmaEpConfig cfg;
  cfg.iterations = 2048;

  ASSERT_EQ(getIterations(nullptr), 128u);
  ASSERT_EQ(getIterations(&cfg), 128u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_config_defaults();
  failures += test_validate_config_allows_null();
  failures += test_validate_config_requires_test_type();
  failures += test_validate_config_rejects_counter_with_flush();
  failures += test_validate_config_rejects_zero_transfer_size();
  failures += test_validate_config_rejects_unaligned_transfer_size();
  failures += test_validate_config_accepts_valid_modes();
  failures += test_get_iterations_current_default();

  if (failures == 0) {
    printf("All sdma-ep config tests passed.\n");
    return 0;
  }
  printf("%d sdma-ep config test(s) failed.\n", failures);
  return 1;
}
