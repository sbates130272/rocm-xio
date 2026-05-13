/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Sanity checks for SDMA opcode constants used by the SDMA endpoint.
 */

#include <cstdio>

#include <hip/hip_runtime.h>

#include "sdma_opcodes.h"
#include "xio-test-assert.h"

static int test_top_level_opcodes() {
  ASSERT_EQ(static_cast<int>(SDMA_OP_NOP), 0);
  ASSERT_EQ(static_cast<int>(SDMA_OP_COPY), 1);
  ASSERT_EQ(static_cast<int>(SDMA_OP_WRITE), 2);
  ASSERT_EQ(static_cast<int>(SDMA_OP_FENCE), 5);
  ASSERT_EQ(static_cast<int>(SDMA_OP_TRAP), 6);
  ASSERT_EQ(static_cast<int>(SDMA_OP_POLL_REGMEM), 8);
  ASSERT_EQ(static_cast<int>(SDMA_OP_ATOMIC), 10);
  ASSERT_EQ(static_cast<int>(SDMA_OP_CONST_FILL), 11);
  ASSERT_EQ(static_cast<int>(SDMA_OP_TIMESTAMP), 13);
  return 0;
}

static int test_subop_copy_write() {
  ASSERT_EQ(static_cast<int>(SDMA_SUBOP_COPY_LINEAR), 0);
  ASSERT_EQ(static_cast<int>(SDMA_SUBOP_COPY_LINEAR_SUB_WINDOW), 36);
  ASSERT_EQ(static_cast<int>(SDMA_SUBOP_WRITE_LINEAR), 0);
  ASSERT_EQ(static_cast<int>(SDMA_ATOMIC_ADD64), 47);
  return 0;
}

#if defined(XIO_SDMA_OSS7) && XIO_SDMA_OSS7
static int test_oss7_constants_present() {
  ASSERT_EQ(static_cast<int>(SDMA_SIGNAL_OP_ADD64_MI4), 111);
  ASSERT_EQ(static_cast<int>(SDMA_WAIT_FUNC_GEQ_MI4), 5);
  ASSERT_EQ(static_cast<unsigned>(SDMA_SUBOP_COPY_LINEAR_PHY_MI4), 0x8u);
  ASSERT_EQ(static_cast<unsigned>(SDMA_SUBOP_COPY_PAGE_TRANSFER_MI4), 0xcu);
  return 0;
}
#endif

int main() {
  int failures = 0;
  failures += test_top_level_opcodes();
  failures += test_subop_copy_write();
#if defined(XIO_SDMA_OSS7) && XIO_SDMA_OSS7
  failures += test_oss7_constants_present();
#endif

  if (failures == 0) {
    printf("All SDMA opcode constant tests passed.\n");
    return 0;
  }
  printf("%d SDMA constant test(s) failed.\n", failures);
  return 1;
}
