/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Wire-format and constant checks for tcp-exchange.hpp.
 */

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

int test_exchange_msg_packed_size() {
  ASSERT_EQ(sizeof(xio::ExchangeMsg), 36u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, qpn), 0u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, rkey), 4u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, lid), 8u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, pad), 10u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, remote_addr), 12u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, gid), 20u);
  return 0;
}

int test_default_port() {
  ASSERT_EQ(xio::TCP_EXCHANGE_PORT, 18515u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_exchange_msg_packed_size();
  failures += test_default_port();
  if (failures == 0) {
    printf("All tcp-exchange layout tests passed.\n");
    return 0;
  }
  printf("%d tcp-exchange layout test(s) failed.\n", failures);
  return 1;
}
