/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for test-ep runtime configuration defaults.
 */

#include <cstdio>

#include "test-ep.h"
#include "xio-endpoint-core.h"
#include "xio-test-assert.h"

int test_test_ep_config_defaults() {
  xio::test_ep::TestEpConfig cfg;
  ASSERT_TRUE(cfg.enableCpuThreads);
  ASSERT_EQ(cfg.doorbell, 0u);
  ASSERT_TRUE(!cfg.emulate);
  ASSERT_EQ(cfg.iterations, 128u);
  ASSERT_TRUE(!cfg.verify);
  ASSERT_EQ(cfg.seed, 1u);
  return 0;
}

int test_endpoint_base_config_ctor() {
  xio::XioEndpointConfig cfg(64, 3);
  ASSERT_EQ(cfg.iterations, 64u);
  ASSERT_EQ(cfg.numThreads, 3u);
  ASSERT_EQ(cfg.delayNs, 0);
  ASSERT_EQ(cfg.memoryMode, 0u);
  ASSERT_TRUE(!cfg.verbose);
  ASSERT_EQ(cfg.verifyPass, 0u);
  ASSERT_EQ(cfg.verifyFail, 0u);
  return 0;
}

int test_test_ep_config_mutation() {
  xio::test_ep::TestEpConfig cfg;
  cfg.enableCpuThreads = false;
  cfg.doorbell = 32;
  cfg.emulate = true;
  cfg.iterations = 7;
  cfg.verify = true;
  cfg.seed = 0x1234;

  ASSERT_TRUE(!cfg.enableCpuThreads);
  ASSERT_EQ(cfg.doorbell, 32u);
  ASSERT_TRUE(cfg.emulate);
  ASSERT_EQ(cfg.iterations, 7u);
  ASSERT_TRUE(cfg.verify);
  ASSERT_EQ(cfg.seed, 0x1234u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_test_ep_config_defaults();
  failures += test_endpoint_base_config_ctor();
  failures += test_test_ep_config_mutation();

  if (failures == 0) {
    printf("All test-ep runtime config tests passed.\n");
    return 0;
  }
  printf("%d test-ep runtime config test(s) failed.\n", failures);
  return 1;
}
