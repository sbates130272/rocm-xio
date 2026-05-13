/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 */

#include <iostream>

#include "xio-endpoint-registry.h"
#include "xio.h"

int main() {
  const auto& registry = getEndpointRegistry();
  if (registry.empty()) {
    std::cerr << "endpoint registry is empty\n";
    return 1;
  }

  const EndpointType type = registry.front().type;
  if (type == EndpointType::UNKNOWN) {
    std::cerr << "unexpected UNKNOWN endpoint type\n";
    return 2;
  }

  const char* name = getEndpointName(type);
  if (name == nullptr || name[0] == '\0') {
    std::cerr << "endpoint name lookup failed\n";
    return 3;
  }

  return 0;
}
