/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for XioComEnqueue/XioComDequeue and doorbell helpers.
 */

#include <cstdint>
#include <cstdio>
#include <cstring>

#include "xio-test-assert.h"
#include "xio.h"

namespace {

struct alignas(8) QueueEntry {
  uint64_t word0;
  uint64_t word1;
  uint64_t word2;
};

int test_xio_com_enqueue_dequeue_roundtrip() {
  const QueueEntry expected = {
    0x0102030405060708ULL,
    0xA0A1A2A3A4A5A6A7ULL,
    0xFFFFFFFF00000000ULL,
  };
  volatile QueueEntry slot {};
  QueueEntry actual {};

  xio::XioComEnqueue<sizeof(QueueEntry)>(&expected, &slot);
  xio::XioComDequeue<sizeof(QueueEntry)>(&slot, &actual);

  ASSERT_EQ(memcmp(&expected, &actual, sizeof(QueueEntry)), 0);
  return 0;
}

int test_xio_com_enqueue_with_fence_template() {
  const QueueEntry expected = {
    0x1111111111111111ULL,
    0x2222222222222222ULL,
    0x3333333333333333ULL,
  };
  volatile QueueEntry slot {};
  QueueEntry actual {};

  xio::XioComEnqueue<sizeof(QueueEntry), true>(&expected, &slot);
  xio::XioComDequeue<sizeof(QueueEntry)>(&slot, &actual);

  ASSERT_EQ(memcmp(&expected, &actual, sizeof(QueueEntry)), 0);
  return 0;
}

int test_xio_com_doorbell_store_32_and_64() {
  uint32_t db32 = 0;
  uint64_t db64 = 0;

  xio::XioComDoorbell(&db32, static_cast<uint32_t>(0xABCD1234U));
  xio::XioComDoorbell(&db64, static_cast<uint64_t>(0x123456789ABCDEF0ULL));

  ASSERT_EQ(db32, 0xABCD1234u);
  ASSERT_EQ(db64, 0x123456789ABCDEF0ULL);
  return 0;
}

int test_ringDoorbell_pointer_and_offset() {
  volatile uint32_t register32 = 0;
  xio::ringDoorbell(&register32, 0x55AA55AAU);
  ASSERT_EQ(register32, 0x55AA55AAu);

  uint32_t mmioWindow[4] = {0, 0, 0, 0};
  xio::ringDoorbell(mmioWindow, 2 * sizeof(uint32_t), 0xDEADBEEFU);
  ASSERT_EQ(mmioWindow[2], 0xDEADBEEFu);
  return 0;
}

} // namespace

int main() {
  int failures = 0;
  failures += test_xio_com_enqueue_dequeue_roundtrip();
  failures += test_xio_com_enqueue_with_fence_template();
  failures += test_xio_com_doorbell_store_32_and_64();
  failures += test_ringDoorbell_pointer_and_offset();

  if (failures == 0) {
    printf("All xio-com tests passed.\n");
    return 0;
  }

  printf("%d xio-com test(s) failed.\n", failures);
  return 1;
}
