/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for tcp-exchange.hpp wire-format layout.
 */

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

int test_exchange_msg_is_packed_36() {
  ASSERT_EQ(sizeof(xio::ExchangeMsg), 36u);
  return 0;
}

int test_exchange_msg_field_offsets() {
  ASSERT_EQ(offsetof(xio::ExchangeMsg, qpn), 0u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, rkey), 4u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, lid), 8u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, pad), 10u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, remote_addr), 12u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, gid), 20u);
  return 0;
}

int test_default_tcp_port_constant() {
  ASSERT_EQ(static_cast<unsigned>(xio::TCP_EXCHANGE_PORT), 18515u);
  return 0;
}

int main() {
  test_exchange_msg_is_packed_36();
  test_exchange_msg_field_offsets();
  test_default_tcp_port_constant();
  printf("test-tcp-exchange-msg: all tests passed\n");
  return 0;
}
