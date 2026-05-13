/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for tcp-exchange helper functions.
 */

#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <thread>
#include <vector>

#include <sys/socket.h>
#include <unistd.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

namespace {

xio::ExchangeMsg makeMessage(uint32_t base) {
  xio::ExchangeMsg msg {};
  msg.qpn = base + 1;
  msg.rkey = base + 2;
  msg.lid = static_cast<uint16_t>(base + 3);
  msg.pad = 0;
  msg.remote_addr = 0xABC00000ULL + base;
  for (size_t i = 0; i < sizeof(msg.gid); ++i) {
    msg.gid[i] = static_cast<uint8_t>(base + i);
  }
  return msg;
}

int test_tcp_send_recv_all_socketpair() {
  int fds[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);

  std::vector<uint8_t> payload(256);
  for (size_t i = 0; i < payload.size(); ++i) {
    payload[i] = static_cast<uint8_t>(i);
  }
  std::vector<uint8_t> received(payload.size(), 0);

  std::thread sender([&]() {
    ASSERT_EQ(xio::tcp_send_all(fds[0], payload.data(), payload.size()), 0);
  });

  ASSERT_EQ(xio::tcp_recv_all(fds[1], received.data(), received.size()), 0);
  sender.join();

  ASSERT_EQ(received.size(), payload.size());
  ASSERT_EQ(memcmp(received.data(), payload.data(), payload.size()), 0);

  close(fds[0]);
  close(fds[1]);
  return 0;
}

int test_exchange_info_bidirectional() {
  int fds[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);

  const xio::ExchangeMsg localA = makeMessage(10);
  const xio::ExchangeMsg localB = makeMessage(20);
  xio::ExchangeMsg remoteA {};
  xio::ExchangeMsg remoteB {};

  std::thread sideA([&]() {
    ASSERT_EQ(xio::exchange_info(fds[0], localA, &remoteA), 0);
  });
  std::thread sideB([&]() {
    ASSERT_EQ(xio::exchange_info(fds[1], localB, &remoteB), 0);
  });

  sideA.join();
  sideB.join();

  ASSERT_EQ(memcmp(&remoteA, &localB, sizeof(xio::ExchangeMsg)), 0);
  ASSERT_EQ(memcmp(&remoteB, &localA, sizeof(xio::ExchangeMsg)), 0);

  close(fds[0]);
  close(fds[1]);
  return 0;
}

int test_tcp_sync_barrier() {
  int fds[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);

  int rcA = -1;
  int rcB = -1;
  std::thread sideA([&]() {
    rcA = xio::tcp_sync(fds[0]);
  });
  std::thread sideB([&]() {
    rcB = xio::tcp_sync(fds[1]);
  });

  sideA.join();
  sideB.join();

  ASSERT_EQ(rcA, 0);
  ASSERT_EQ(rcB, 0);

  close(fds[0]);
  close(fds[1]);
  return 0;
}

int test_tcp_recv_all_reports_eof() {
  int fds[2] = {-1, -1};
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);

  close(fds[0]);

  std::array<uint8_t, 8> buf {};
  ASSERT_EQ(xio::tcp_recv_all(fds[1], buf.data(), buf.size()), -1);

  close(fds[1]);
  return 0;
}

} // namespace

int main() {
  int failures = 0;
  failures += test_tcp_send_recv_all_socketpair();
  failures += test_exchange_info_bidirectional();
  failures += test_tcp_sync_barrier();
  failures += test_tcp_recv_all_reports_eof();

  if (failures == 0) {
    printf("All tcp-exchange tests passed.\n");
    return 0;
  }

  printf("%d tcp-exchange test(s) failed.\n", failures);
  return 1;
}
