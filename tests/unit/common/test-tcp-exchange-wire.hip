/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for TCP exchange wire format and send/recv helpers.
 */

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>

#include <sys/socket.h>
#include <unistd.h>

#include <hip/hip_runtime.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

int test_exchange_msg_packed_layout() {
  static_assert(sizeof(xio::ExchangeMsg) == 36, "ExchangeMsg wire size");
  ASSERT_EQ(offsetof(xio::ExchangeMsg, qpn), 0u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, rkey), 4u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, lid), 8u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, pad), 10u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, remote_addr), 12u);
  ASSERT_EQ(offsetof(xio::ExchangeMsg, gid), 20u);
  return 0;
}

int test_tcp_send_recv_roundtrip() {
  int fds[2];
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);

  xio::ExchangeMsg out = {};
  out.qpn = 0x11223344;
  out.rkey = 0x55667788;
  out.lid = 0xAABB;
  out.pad = 0;
  out.remote_addr = 0xDEADBEEFCAFEBABEULL;
  memset(out.gid, 0x5A, sizeof(out.gid));

  ASSERT_EQ(xio::tcp_send_all(fds[0], &out, sizeof(out)), 0);

  xio::ExchangeMsg in = {};
  ASSERT_EQ(xio::tcp_recv_all(fds[1], &in, sizeof(in)), 0);

  ASSERT_EQ(in.qpn, out.qpn);
  ASSERT_EQ(in.rkey, out.rkey);
  ASSERT_EQ(in.lid, out.lid);
  ASSERT_EQ(in.pad, out.pad);
  ASSERT_EQ(in.remote_addr, out.remote_addr);
  ASSERT_EQ(memcmp(in.gid, out.gid, sizeof(out.gid)), 0);

  close(fds[0]);
  close(fds[1]);
  return 0;
}

int test_tcp_exchange_port_constant() {
  ASSERT_EQ(xio::TCP_EXCHANGE_PORT, 18515);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_exchange_msg_packed_layout();
  failures += test_tcp_send_recv_roundtrip();
  failures += test_tcp_exchange_port_constant();

  if (failures == 0) {
    printf("All tcp-exchange wire tests passed.\n");
    return 0;
  }
  printf("%d tcp-exchange wire test(s) failed.\n", failures);
  return 1;
}
