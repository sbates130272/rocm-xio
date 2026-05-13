/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for sdma-ep configuration defaults and validation.
 */

#include <cstdio>
#include <string>

#include "sdma-ep.h"
#include "xio-test-assert.h"

using namespace xio::sdma_ep;

int test_defaults() {
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

int test_validate_requires_subcommand() {
  SdmaEpConfig cfg;
  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  ASSERT_NE(err.find("Missing test subcommand"), std::string::npos);
  return 0;
}

int test_validate_conflicting_completion_mode() {
  SdmaEpConfig cfg;
  cfg.testType = "ping-pong";
  cfg.useCounter = true;
  cfg.useFlush = true;

  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(!err.empty());
  ASSERT_NE(err.find("Cannot use both --use-counter and --use-flush"),
            std::string::npos);
  return 0;
}

int test_validate_transfer_size_rules() {
  SdmaEpConfig cfg;
  cfg.testType = "p2p";

  cfg.transferSize = 0;
  std::string err = validateConfig(&cfg);
  ASSERT_NE(err.find("transfer-size must be > 0"), std::string::npos);

  cfg.transferSize = 3;
  err = validateConfig(&cfg);
  ASSERT_NE(err.find("transfer-size must be a multiple of 4"),
            std::string::npos);
  return 0;
}

int test_validate_good_config() {
  SdmaEpConfig cfg;
  cfg.testType = "buffer-reuse";
  cfg.transferSize = 4096;
  cfg.useCounter = true;
  cfg.useFlush = false;
  cfg.iterations = 256;

  std::string err = validateConfig(&cfg);
  ASSERT_TRUE(err.empty());
  return 0;
}

int main() {
  int failures = 0;
  failures += test_defaults();
  failures += test_validate_requires_subcommand();
  failures += test_validate_conflicting_completion_mode();
  failures += test_validate_transfer_size_rules();
  failures += test_validate_good_config();

  if (failures == 0) {
    printf("All sdma-ep config tests passed.\n");
    return 0;
  }
  printf("%d sdma-ep config test(s) failed.\n", failures);
  return 1;
}
