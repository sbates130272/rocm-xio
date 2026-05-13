/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for tcp_send_all / tcp_recv_all using a Unix socketpair.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <sys/socket.h>
#include <unistd.h>

#include <hip/hip_runtime.h>

#include "tcp-exchange.hpp"
#include "xio-test-assert.h"

int test_send_recv_roundtrip() {
  int fds[2];
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);
  const char payload[] = "rocm-xio-tcp";
  size_t len = sizeof(payload);
  ASSERT_EQ(xio::tcp_send_all(fds[0], payload, len), 0);
  char buf[64] = {};
  ASSERT_EQ(xio::tcp_recv_all(fds[1], buf, len), 0);
  ASSERT_EQ(memcmp(buf, payload, len), 0);
  close(fds[0]);
  close(fds[1]);
  return 0;
}

int test_recv_detects_eof() {
  int fds[2];
  ASSERT_EQ(socketpair(AF_UNIX, SOCK_STREAM, 0, fds), 0);
  close(fds[0]);
  char one;
  ASSERT_NE(xio::tcp_recv_all(fds[1], &one, 1), 0);
  close(fds[1]);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_send_recv_roundtrip();
  failures += test_recv_detects_eof();
  if (failures == 0) {
    printf("All tcp-exchange I/O tests passed.\n");
    return 0;
  }
  printf("%d tcp-exchange I/O test(s) failed.\n", failures);
  return 1;
}
