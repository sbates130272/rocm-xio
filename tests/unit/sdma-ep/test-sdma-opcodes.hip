/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for SDMA opcode constants and packet field wiring.
 */

#include <cstdint>
#include <cstdio>

#include "sdma_opcodes.h"
#include "sdma_pkt_struct.h"
#include "xio-test-assert.h"

int test_opcode_constants() {
  ASSERT_EQ(SDMA_OP_NOP, 0u);
  ASSERT_EQ(SDMA_OP_COPY, 1u);
  ASSERT_EQ(SDMA_OP_WRITE, 2u);
  ASSERT_EQ(SDMA_OP_FENCE, 5u);
  ASSERT_EQ(SDMA_OP_ATOMIC, 10u);
  ASSERT_EQ(SDMA_OP_CONST_FILL, 11u);

  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR, 0u);
  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR_SUB_WINDOW, 36u);
  ASSERT_EQ(SDMA_SUBOP_WRITE_LINEAR, 0u);
  ASSERT_EQ(SDMA_ATOMIC_ADD64, 47u);
  return 0;
}

int test_copy_linear_packet_layout() {
  SDMA_PKT_COPY_LINEAR pkt = {};
  pkt.HEADER_UNION.op = SDMA_OP_COPY;
  pkt.HEADER_UNION.sub_op = SDMA_SUBOP_COPY_LINEAR;
  pkt.COUNT_UNION.count = 4095;
  pkt.SRC_ADDR_LO_UNION.src_addr_31_0 = 0x12345678u;
  pkt.SRC_ADDR_HI_UNION.src_addr_63_32 = 0x9abcdef0u;
  pkt.DST_ADDR_LO_UNION.dst_addr_31_0 = 0x11112222u;
  pkt.DST_ADDR_HI_UNION.dst_addr_63_32 = 0x33334444u;

  ASSERT_EQ(pkt.HEADER_UNION.op, SDMA_OP_COPY);
  ASSERT_EQ(pkt.HEADER_UNION.sub_op, SDMA_SUBOP_COPY_LINEAR);
  ASSERT_EQ(pkt.COUNT_UNION.count, 4095u);
  ASSERT_EQ(pkt.SRC_ADDR_LO_UNION.src_addr_31_0, 0x12345678u);
  ASSERT_EQ(pkt.SRC_ADDR_HI_UNION.src_addr_63_32, 0x9abcdef0u);
  ASSERT_EQ(pkt.DST_ADDR_LO_UNION.dst_addr_31_0, 0x11112222u);
  ASSERT_EQ(pkt.DST_ADDR_HI_UNION.dst_addr_63_32, 0x33334444u);
  return 0;
}

int test_atomic_packet_layout() {
  SDMA_PKT_ATOMIC pkt = {};
  pkt.HEADER_UNION.op = SDMA_OP_ATOMIC;
  pkt.HEADER_UNION.operation = SDMA_ATOMIC_ADD64;
  pkt.ADDR_LO_UNION.addr_31_0 = 0xaaaabbbbu;
  pkt.ADDR_HI_UNION.addr_63_32 = 0xccccddddu;
  pkt.SRC_DATA_LO_UNION.src_data_31_0 = 1u;
  pkt.SRC_DATA_HI_UNION.src_data_63_32 = 0u;

  ASSERT_EQ(pkt.HEADER_UNION.op, SDMA_OP_ATOMIC);
  ASSERT_EQ(pkt.HEADER_UNION.operation, SDMA_ATOMIC_ADD64);
  ASSERT_EQ(pkt.ADDR_LO_UNION.addr_31_0, 0xaaaabbbbu);
  ASSERT_EQ(pkt.ADDR_HI_UNION.addr_63_32, 0xccccddddu);
  ASSERT_EQ(pkt.SRC_DATA_LO_UNION.src_data_31_0, 1u);
  ASSERT_EQ(pkt.SRC_DATA_HI_UNION.src_data_63_32, 0u);
  return 0;
}

int test_subwindow_packet_layout() {
  SDMA_PKT_LINEAR_LARGE_SUB_WINDOW_COPY pkt = {};
  pkt.HEADER_UNION.op = SDMA_OP_COPY;
  pkt.HEADER_UNION.sub_op = SDMA_SUBOP_COPY_LINEAR_SUB_WINDOW;
  pkt.SRC_X_UNION.src_x = 16;
  pkt.SRC_Y_UNION.src_y = 32;
  pkt.DST_X_UNION.dst_x = 64;
  pkt.DST_Y_UNION.dst_y = 96;
  pkt.RECT_X_UNION.rect_x = 127;
  pkt.RECT_Y_UNION.rect_y = 255;

  ASSERT_EQ(pkt.HEADER_UNION.op, SDMA_OP_COPY);
  ASSERT_EQ(pkt.HEADER_UNION.sub_op, SDMA_SUBOP_COPY_LINEAR_SUB_WINDOW);
  ASSERT_EQ(pkt.SRC_X_UNION.src_x, 16u);
  ASSERT_EQ(pkt.SRC_Y_UNION.src_y, 32u);
  ASSERT_EQ(pkt.DST_X_UNION.dst_x, 64u);
  ASSERT_EQ(pkt.DST_Y_UNION.dst_y, 96u);
  ASSERT_EQ(pkt.RECT_X_UNION.rect_x, 127u);
  ASSERT_EQ(pkt.RECT_Y_UNION.rect_y, 255u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_opcode_constants();
  failures += test_copy_linear_packet_layout();
  failures += test_atomic_packet_layout();
  failures += test_subwindow_packet_layout();

  if (failures == 0) {
    printf("All sdma opcode tests passed.\n");
    return 0;
  }
  printf("%d sdma opcode test(s) failed.\n", failures);
  return 1;
}
