/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for endpoint-registry helper APIs.
 */

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdio>
#include <string>

#include <unistd.h>

#include "xio-endpoint-registry.h"
#include "xio-test-assert.h"

namespace {

std::string captureListAvailableEndpoints() {
  fflush(stdout);

  int pipefd[2] = {-1, -1};
  if (pipe(pipefd) != 0) {
    return "";
  }

  int savedStdout = dup(STDOUT_FILENO);
  if (savedStdout < 0) {
    close(pipefd[0]);
    close(pipefd[1]);
    return "";
  }

  dup2(pipefd[1], STDOUT_FILENO);
  close(pipefd[1]);

  listAvailableEndpoints();
  fflush(stdout);

  dup2(savedStdout, STDOUT_FILENO);
  close(savedStdout);

  std::string output;
  std::array<char, 256> buf {};
  for (;;) {
    const ssize_t n = read(pipefd[0], buf.data(), buf.size());
    if (n <= 0) {
      break;
    }
    output.append(buf.data(), static_cast<size_t>(n));
  }
  close(pipefd[0]);
  return output;
}

int test_registry_case_insensitive_lookup() {
  const auto& registry = getEndpointRegistry();
  ASSERT_TRUE(!registry.empty());

  for (const auto& ep : registry) {
    std::string upper = ep.name;
    std::transform(upper.begin(), upper.end(), upper.begin(), [](char c) {
      return static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    });

    ASSERT_TRUE(isValidEndpoint(upper));
    ASSERT_EQ(getEndpointType(upper), ep.type);
  }
  return 0;
}

int test_registry_unknown_paths() {
  ASSERT_TRUE(!isValidEndpoint("definitely-not-an-endpoint"));
  ASSERT_EQ(getEndpointType("definitely-not-an-endpoint"), EndpointType::UNKNOWN);
  ASSERT_STREQ(getEndpointName(EndpointType::UNKNOWN), "unknown");

  const EndpointInfo unknown = getEndpointInfo(EndpointType::UNKNOWN);
  ASSERT_EQ(unknown.type, EndpointType::UNKNOWN);
  ASSERT_STREQ(unknown.name.c_str(), "unknown");
  return 0;
}

int test_registry_getEndpointInfo_roundtrip() {
  const auto& registry = getEndpointRegistry();
  for (const auto& ep : registry) {
    const EndpointInfo byType = getEndpointInfo(ep.type);
    ASSERT_STREQ(byType.name.c_str(), ep.name.c_str());
    ASSERT_STREQ(byType.description.c_str(), ep.description.c_str());
    ASSERT_EQ(byType.type, ep.type);
  }
  return 0;
}

int test_listAvailableEndpoints_output_contains_entries() {
  const auto& registry = getEndpointRegistry();
  const std::string output = captureListAvailableEndpoints();
  ASSERT_TRUE(!output.empty());
  ASSERT_TRUE(output.find("Available endpoints:") != std::string::npos);

  for (const auto& ep : registry) {
    ASSERT_TRUE(output.find(ep.name) != std::string::npos);
  }
  return 0;
}

} // namespace

int main() {
  int failures = 0;
  failures += test_registry_case_insensitive_lookup();
  failures += test_registry_unknown_paths();
  failures += test_registry_getEndpointInfo_roundtrip();
  failures += test_listAvailableEndpoints_output_contains_entries();

  if (failures == 0) {
    printf("All endpoint-registry helper tests passed.\n");
    return 0;
  }

  printf("%d endpoint-registry helper test(s) failed.\n", failures);
  return 1;
}
