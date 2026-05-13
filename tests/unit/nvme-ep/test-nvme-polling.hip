/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for nvme-ep polling helpers.
 */

#include <cstdio>

#include "nvme-ep.h"
#include "xio-test-assert.h"

using namespace xio::nvme_ep;

int test_sqe_poll_detects_command_change() {
  volatile sqeType slot = {};
  sqeType last = {};
  last.command_id = 7;

  slot.command_id = 8;
  slot.opcode = nvme_cmd_read;

  sqeType observed = sqePoll(last, &slot);
  ASSERT_EQ(observed.command_id, 8);
  ASSERT_EQ(observed.opcode, static_cast<uint8_t>(nvme_cmd_read));
  return 0;
}

int test_cqe_poll_detects_sq_head_progress() {
  volatile cqeType slot = {};
  cqeType last = {};
  last.command_id = 10;
  last.sq_head = 30;

  slot.command_id = 10;
  slot.sq_head = 31;
  slot.status = NVME_STATUS_MAKE(1, 0, 0);

  uint16_t sq_head_out = 0;
  cqeType observed = cqePoll(last, &slot, last.sq_head, &sq_head_out, nullptr);
  ASSERT_EQ(observed.sq_head, 31);
  ASSERT_EQ(sq_head_out, 31);
  return 0;
}

int test_cqe_poll_wraparound_progress() {
  volatile cqeType slot = {};
  cqeType last = {};
  last.command_id = 1;
  last.sq_head = 65535;

  slot.command_id = 1;
  slot.sq_head = 2;

  uint16_t sq_head_out = 0;
  cqeType observed = cqePoll(last, &slot, last.sq_head, &sq_head_out, nullptr);
  ASSERT_EQ(observed.sq_head, 2);
  ASSERT_EQ(sq_head_out, 2);
  return 0;
}

int test_cqe_poll_falls_back_to_command_id() {
  volatile cqeType slot = {};
  cqeType last = {};
  last.command_id = 7;
  last.sq_head = 20;

  slot.command_id = 8;
  slot.sq_head = 20;

  uint16_t sq_head_out = 0;
  cqeType observed = cqePoll(last, &slot, last.sq_head, &sq_head_out, nullptr);
  ASSERT_EQ(observed.command_id, 8);
  ASSERT_EQ(sq_head_out, 20);
  return 0;
}

int test_cqe_poll_honors_stop_requested() {
  volatile cqeType slot = {};
  cqeType last = {};
  last.command_id = 4;
  last.sq_head = 9;

  slot.command_id = 5;
  slot.sq_head = 10;

  volatile bool stop_requested = true;
  uint16_t sq_head_out = 0;
  cqeType observed =
    cqePoll(last, &slot, last.sq_head, &sq_head_out, &stop_requested);
  ASSERT_EQ(observed.command_id, last.command_id);
  ASSERT_EQ(observed.sq_head, last.sq_head);
  ASSERT_EQ(sq_head_out, last.sq_head);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_sqe_poll_detects_command_change();
  failures += test_cqe_poll_detects_sq_head_progress();
  failures += test_cqe_poll_wraparound_progress();
  failures += test_cqe_poll_falls_back_to_command_id();
  failures += test_cqe_poll_honors_stop_requested();

  if (failures == 0) {
    printf("All nvme polling tests passed.\n");
    return 0;
  }
  printf("%d nvme polling test(s) failed.\n", failures);
  return 1;
}
