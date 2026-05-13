/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for TCP exchange helpers.
 */

#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <thread>

#include <sys/socket.h>
#include <unistd.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

int test_tcp_send_recv_all() {
  int sv[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, sv), 0);

  std::array<uint8_t, 6> tx = {1, 2, 3, 4, 5, 6};
  std::array<uint8_t, 6> rx = {};

  ASSERT_EQ(xio::tcp_send_all(sv[0], tx.data(), tx.size()), 0);
  ASSERT_EQ(xio::tcp_recv_all(sv[1], rx.data(), rx.size()), 0);
  ASSERT_EQ(memcmp(tx.data(), rx.data(), tx.size()), 0);

  close(sv[0]);
  close(sv[1]);
  return 0;
}

int test_exchange_info() {
  int sv[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, sv), 0);

  xio::ExchangeMsg local_a = {};
  local_a.qpn = 11;
  local_a.rkey = 0xABCDEF01u;
  local_a.remote_addr = 0x1111222233334444ULL;
  local_a.gid[0] = 0xA1;

  xio::ExchangeMsg local_b = {};
  local_b.qpn = 22;
  local_b.rkey = 0x10203040u;
  local_b.remote_addr = 0x9999888877776666ULL;
  local_b.gid[15] = 0xB2;

  xio::ExchangeMsg remote_a = {};
  xio::ExchangeMsg remote_b = {};
  int rc_a = -1;
  int rc_b = -1;

  std::thread t1([&]() { rc_a = xio::exchange_info(sv[0], local_a, &remote_a); });
  std::thread t2([&]() { rc_b = xio::exchange_info(sv[1], local_b, &remote_b); });
  t1.join();
  t2.join();

  ASSERT_EQ(rc_a, 0);
  ASSERT_EQ(rc_b, 0);
  ASSERT_EQ(remote_a.qpn, local_b.qpn);
  ASSERT_EQ(remote_a.rkey, local_b.rkey);
  ASSERT_EQ(remote_b.qpn, local_a.qpn);
  ASSERT_EQ(remote_b.rkey, local_a.rkey);
  ASSERT_EQ(remote_a.gid[15], local_b.gid[15]);
  ASSERT_EQ(remote_b.gid[0], local_a.gid[0]);

  close(sv[0]);
  close(sv[1]);
  return 0;
}

int test_tcp_sync() {
  int sv[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, sv), 0);

  int rc_a = -1;
  int rc_b = -1;
  std::thread t1([&]() { rc_a = xio::tcp_sync(sv[0]); });
  std::thread t2([&]() { rc_b = xio::tcp_sync(sv[1]); });
  t1.join();
  t2.join();

  ASSERT_EQ(rc_a, 0);
  ASSERT_EQ(rc_b, 0);

  close(sv[0]);
  close(sv[1]);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_tcp_send_recv_all();
  failures += test_exchange_info();
  failures += test_tcp_sync();

  if (failures == 0) {
    printf("All tcp-exchange tests passed.\n");
    return 0;
  }
  printf("%d tcp-exchange test(s) failed.\n", failures);
  return 1;
}
