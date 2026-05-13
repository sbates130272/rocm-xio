/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio-cli-options registration and parsing behavior.
 */

#include <cstdio>
#include <string>
#include <vector>

#include <CLI/CLI.hpp>

#include "xio-test-assert.h"

// xio-cli-options is built into xio-tester, not librocm-xio.
// Include the implementation directly so this unit test can
// exercise the registration and validators.
#include "../../../src/tester/xio-cli-options.cpp"

namespace {

bool parseArgs(CLI::App& app, const std::vector<std::string>& argv) {
  std::vector<std::string> args = argv;
  try {
    app.parse(args);
    return true;
  } catch (const CLI::ParseError&) {
    return false;
  }
}

int test_test_ep_cli_options_parse() {
  CLI::App app("test-ep-cli");
  xio::test_ep::TestEpConfig cfg;
  registerTestEpCliOptions(app, &cfg);

  const bool ok = parseArgs(app, {"--iterations", "9", "--doorbell", "16",
                                  "--emulate", "--verify", "--seed", "77"});
  ASSERT_TRUE(ok);
  ASSERT_EQ(cfg.iterations, 9u);
  ASSERT_EQ(cfg.doorbell, 16u);
  ASSERT_TRUE(cfg.emulate);
  ASSERT_TRUE(cfg.verify);
  ASSERT_EQ(cfg.seed, 77u);
  return 0;
}

int test_nvme_cli_options_parse_and_validation() {
  CLI::App validApp("nvme-cli-valid");
  xio::nvme_ep::nvmeEpConfig validCfg;
  registerNvmeEpCliOptions(validApp, &validCfg);

  const bool valid = parseArgs(validApp, {"--controller", "/dev/nvme0",
                                          "--access-pattern", "sequential",
                                          "--queue-length", "2048",
                                          "--num-queues", "3", "--read-io", "4",
                                          "--write-io", "2", "--batch-size",
                                          "8", "--verify"});
  ASSERT_TRUE(valid);
  ASSERT_STREQ(validCfg.controller.c_str(), "/dev/nvme0");
  ASSERT_STREQ(validCfg.ioParams.accessPattern.c_str(), "sequential");
  ASSERT_EQ(validCfg.queueLength, static_cast<uint16_t>(2048));
  ASSERT_EQ(validCfg.numQueues, 3u);
  ASSERT_EQ(validCfg.ioParams.readIo, 4);
  ASSERT_EQ(validCfg.ioParams.writeIo, 2);
  ASSERT_EQ(validCfg.ioParams.batchSize, 8u);
  ASSERT_TRUE(validCfg.verify);

  CLI::App invalidApp("nvme-cli-invalid");
  xio::nvme_ep::nvmeEpConfig invalidCfg;
  registerNvmeEpCliOptions(invalidApp, &invalidCfg);
  const bool invalid = parseArgs(invalidApp, {"--controller", "/dev/nvme0",
                                              "--queue-length", "1000"});
  ASSERT_TRUE(!invalid);
  return 0;
}

int test_rdma_cli_options_parse_and_exclusion() {
  CLI::App validApp("rdma-cli-valid");
  rdma_ep::RdmaEpConfig validCfg;
  registerRdmaEpCliOptions(validApp, &validCfg);

  const bool valid = parseArgs(validApp, {"--provider", "pensando", "--device",
                                          "rocm-rdma-ionic0", "--no-loopback",
                                          "--batch-size", "4", "--num-queues",
                                          "2", "--infinite", "--seed", "9"});
  ASSERT_TRUE(valid);
  ASSERT_STREQ(validCfg.providerStr.c_str(), "pensando");
  ASSERT_STREQ(validCfg.deviceName.c_str(), "rocm-rdma-ionic0");
  ASSERT_TRUE(!validCfg.loopback);
  ASSERT_EQ(validCfg.batchSize, 4u);
  ASSERT_EQ(validCfg.numQueues, 2u);
  ASSERT_TRUE(validCfg.infiniteMode);
  ASSERT_EQ(validCfg.seed, 9u);

  CLI::App invalidApp("rdma-cli-invalid");
  rdma_ep::RdmaEpConfig invalidCfg;
  registerRdmaEpCliOptions(invalidApp, &invalidCfg);
  const bool invalid = parseArgs(invalidApp, {"--server", "--client"});
  ASSERT_TRUE(!invalid);
  return 0;
}

int test_sdma_cli_options_parse_detect_type_and_transform() {
  CLI::App app("sdma-cli");
  sdma_ep::SdmaEpConfig cfg;
  registerSdmaEpCliOptions(app, &cfg);

  const bool ok =
    parseArgs(app, {"-n", "10", "-s", "4k", "p2p", "--to-host", "--verify"});
  ASSERT_TRUE(ok);
  detectSdmaTestType(app, &cfg);
  ASSERT_STREQ(cfg.testType.c_str(), "p2p");
  ASSERT_EQ(cfg.iterations, 10u);
  ASSERT_EQ(cfg.transferSize, static_cast<size_t>(4096));
  ASSERT_TRUE(cfg.useHostDst);
  ASSERT_TRUE(cfg.verifyData);

  CLI::App invalidApp("sdma-cli-invalid");
  sdma_ep::SdmaEpConfig invalidCfg;
  registerSdmaEpCliOptions(invalidApp, &invalidCfg);
  const bool invalid = parseArgs(invalidApp, {"-s", "0", "p2p"});
  ASSERT_TRUE(!invalid);
  return 0;
}

} // namespace

int main() {
  int failures = 0;
  failures += test_test_ep_cli_options_parse();
  failures += test_nvme_cli_options_parse_and_validation();
  failures += test_rdma_cli_options_parse_and_exclusion();
  failures += test_sdma_cli_options_parse_detect_type_and_transform();

  if (failures == 0) {
    printf("All tester CLI options tests passed.\n");
    return 0;
  }

  printf("%d tester CLI options test(s) failed.\n", failures);
  return 1;
}
