/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for SDMA opcode constants in sdma_opcodes.h.
 */

#include <cstdio>

#include <hip/hip_runtime.h>

#include "sdma_opcodes.h"
#include "xio-test-assert.h"

int test_top_level_opcodes() {
  ASSERT_EQ(SDMA_OP_NOP, 0u);
  ASSERT_EQ(SDMA_OP_COPY, 1u);
  ASSERT_EQ(SDMA_OP_WRITE, 2u);
  ASSERT_EQ(SDMA_OP_FENCE, 5u);
  ASSERT_EQ(SDMA_OP_TRAP, 6u);
  ASSERT_EQ(SDMA_OP_ATOMIC, 10u);
  ASSERT_EQ(SDMA_OP_CONST_FILL, 11u);
  ASSERT_EQ(SDMA_OP_POLL_REGMEM, 8u);
  ASSERT_EQ(SDMA_OP_TIMESTAMP, 13u);
  return 0;
}

int test_pre_oss7_subops() {
  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR, 0u);
  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR_SUB_WINDOW, 36u);
  ASSERT_EQ(SDMA_SUBOP_WRITE_LINEAR, 0u);
  ASSERT_EQ(SDMA_ATOMIC_ADD64, 47u);
  return 0;
}

#if XIO_SDMA_OSS7
int test_oss7_constants_present() {
  ASSERT_EQ(SDMA_SIGNAL_OP_ADD64_MI4, 111u);
  ASSERT_EQ(SDMA_WAIT_FUNC_GEQ_MI4, 5u);
  ASSERT_EQ(SDMA_SUBOP_COPY_LINEAR_PHY_MI4, 0x8u);
  ASSERT_EQ(SDMA_SUBOP_FENCE_MI4, 0x0u);
  return 0;
}
#endif

int main() {
  int failures = 0;
  failures += test_top_level_opcodes();
  failures += test_pre_oss7_subops();
#if XIO_SDMA_OSS7
  failures += test_oss7_constants_present();
#endif

  if (failures == 0) {
    printf("All SDMA opcode tests passed.\n");
    return 0;
  }
  printf("%d SDMA opcode test(s) failed.\n", failures);
  return 1;
}
