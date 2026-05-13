/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for test-ep.h queue layout and magic constants.
 */

#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"

int test_test_ep_magic_constants() {
  ASSERT_EQ(xio::test_ep::magicId, 0xDEADBEEFCAFEBABEULL);
  ASSERT_EQ(xio::test_ep::cqeMagicId, 0xBABECAFEBEEFDEADULL);
  return 0;
}

int test_test_ep_queue_entry_sizes() {
  ASSERT_EQ(xio::test_ep::sqeSize, 64u);
  ASSERT_EQ(xio::test_ep::cqeSize, 16u);
  return 0;
}

int main() {
  test_test_ep_magic_constants();
  test_test_ep_queue_entry_sizes();
  printf("test-ep-constants: all tests passed\n");
  return 0;
}
