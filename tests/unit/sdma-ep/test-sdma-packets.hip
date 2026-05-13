/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for SDMA opcode constants and packet struct sizes used by
 * sdma-ep. Header static_asserts must succeed; this file adds value-range
 * checks that fail loudly if constants drift.
 */

#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "sdma_opcodes.h"
#include "sdma_pkt_struct.h"
#include "xio-test-assert.h"

#if XIO_SDMA_OSS7
#include "sdma_pkt_struct_mi4.h"
#endif

int test_sdma_opcode_values() {
  ASSERT_EQ(SDMA_OP_NOP, 0u);
  ASSERT_EQ(SDMA_OP_COPY, 1u);
  ASSERT_EQ(SDMA_OP_WRITE, 2u);
  ASSERT_EQ(SDMA_OP_FENCE, 5u);
  ASSERT_EQ(SDMA_OP_TRAP, 6u);
  ASSERT_EQ(SDMA_OP_ATOMIC, 10u);
  ASSERT_EQ(SDMA_OP_CONST_FILL, 11u);
  ASSERT_EQ(SDMA_OP_TIMESTAMP, 13u);
  ASSERT_EQ(SDMA_OP_POLL_REGMEM, 8u);
  return 0;
}

int test_sdma_subop_copy_linear() {
  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR, 0u);
  ASSERT_EQ(SDMA_SUBOP_WRITE_LINEAR, 0u);
  return 0;
}

int test_sdma_packet_sizes() {
  ASSERT_EQ(sizeof(SDMA_PKT_COPY_LINEAR), 7u * sizeof(unsigned int));
  ASSERT_EQ(sizeof(SDMA_PKT_WRITE_UNTILED), 5u * sizeof(unsigned int));
  ASSERT_EQ(sizeof(SDMA_PKT_FENCE), 4u * sizeof(unsigned int));
  return 0;
}

#if XIO_SDMA_OSS7
int test_sdma_mi4_opcode_constants() {
  ASSERT_EQ(SDMA_SIGNAL_OP_ADD64_MI4, 111u);
  ASSERT_EQ(SDMA_WAIT_FUNC_GEQ_MI4, 5u);
  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR_PHY_MI4, 0x8u);
  return 0;
}

int test_sdma_mi4_fence_packet_size() {
  ASSERT_EQ(sizeof(SDMA_PKT_FENCE_MI4), 4u * sizeof(unsigned int));
  return 0;
}
#endif

int main() {
  test_sdma_opcode_values();
  test_sdma_subop_copy_linear();
  test_sdma_packet_sizes();
#if XIO_SDMA_OSS7
  test_sdma_mi4_opcode_constants();
  test_sdma_mi4_fence_packet_size();
#endif
  printf("test-sdma-packets: all tests passed\n");
  return 0;
}
