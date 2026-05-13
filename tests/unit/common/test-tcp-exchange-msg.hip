/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Compile-time and runtime checks for tcp-exchange.hpp wire layout.
 */

#include <cstddef>
#include <cstdio>

#include <hip/hip_runtime.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

static_assert(sizeof(xio::ExchangeMsg) == 36,
              "ExchangeMsg wire size must match RDMA TCP exchange protocol");
static_assert(offsetof(xio::ExchangeMsg, qpn) == 0, "qpn offset");
static_assert(offsetof(xio::ExchangeMsg, rkey) == 4, "rkey offset");
static_assert(offsetof(xio::ExchangeMsg, remote_addr) == 12,
              "remote_addr offset");
static_assert(offsetof(xio::ExchangeMsg, gid) == 20, "gid offset");

static int test_tcp_exchange_port_constant() {
  ASSERT_EQ(static_cast<int>(xio::TCP_EXCHANGE_PORT), 18515);
  return 0;
}

static int test_exchange_msg_zero_initialized() {
  xio::ExchangeMsg m{};
  ASSERT_EQ(m.qpn, 0u);
  ASSERT_EQ(m.rkey, 0u);
  ASSERT_EQ(m.lid, 0u);
  ASSERT_EQ(m.pad, 0u);
  ASSERT_EQ(m.remote_addr, 0u);
  for (size_t i = 0; i < sizeof m.gid; i++) {
    ASSERT_EQ(m.gid[i], 0);
  }
  return 0;
}

int main() {
  int failures = 0;
  failures += test_tcp_exchange_port_constant();
  failures += test_exchange_msg_zero_initialized();

  if (failures == 0) {
    printf("All tcp-exchange layout tests passed.\n");
    return 0;
  }
  printf("%d tcp-exchange test(s) failed.\n", failures);
  return 1;
}
