/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for test-ep magic identifiers and queue entry sizes.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "test-ep.h"
#include "xio-test-assert.h"

int test_magic_constants() {
  ASSERT_EQ(xio::test_ep::magicId, 0xDEADBEEFCAFEBABEULL);
  ASSERT_EQ(xio::test_ep::cqeMagicId, 0xBABECAFEBEEFDEADULL);
  return 0;
}

int test_queue_entry_sizes() {
  ASSERT_EQ(xio::test_ep::sqeSize, 64u);
  ASSERT_EQ(xio::test_ep::cqeSize, 16u);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_magic_constants();
  failures += test_queue_entry_sizes();
  if (failures == 0) {
    printf("All test-ep constant tests passed.\n");
    return 0;
  }
  printf("%d test-ep constant test(s) failed.\n", failures);
  return 1;
}
