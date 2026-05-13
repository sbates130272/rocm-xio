/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for dynamic-loader helpers in xio-rdma-check.h.
 */

#include <cstddef>
#include <cstdio>

#include <dlfcn.h>

#include "xio-rdma-check.h"
#include "xio-test-assert.h"

using strlen_fn_t = size_t (*)(const char*);
using puts_fn_t = int (*)(const char*);

int test_dlsym_load() {
  void* handle = dlopen("libc.so.6", RTLD_LAZY | RTLD_LOCAL);
  ASSERT_TRUE(handle != nullptr);

  strlen_fn_t strlen_fn = nullptr;
  ASSERT_EQ(xio_rdma::dlsym_load(strlen_fn, handle, "strlen", "unit-test"), 0);
  ASSERT_TRUE(strlen_fn != nullptr);
  ASSERT_EQ(strlen_fn("rocm-xio"), 8u);

  dlclose(handle);
  return 0;
}

int test_dlsym_load_optional() {
  void* handle = dlopen("libc.so.6", RTLD_LAZY | RTLD_LOCAL);
  ASSERT_TRUE(handle != nullptr);

  puts_fn_t puts_fn = nullptr;
  ASSERT_EQ(xio_rdma::dlsym_load_optional(puts_fn, handle, "puts"), 0);
  ASSERT_TRUE(puts_fn != nullptr);

  puts_fn_t missing = reinterpret_cast<puts_fn_t>(0x1);
  ASSERT_EQ(xio_rdma::dlsym_load_optional(missing, handle,
                                          "xio_symbol_that_does_not_exist"),
            -1);
  ASSERT_TRUE(missing == nullptr);

  dlclose(handle);
  return 0;
}

int test_dlsym_load_prefixed() {
  void* handle = dlopen("libc.so.6", RTLD_LAZY | RTLD_LOCAL);
  ASSERT_TRUE(handle != nullptr);

  strlen_fn_t strlen_fn = nullptr;
  ASSERT_EQ(xio_rdma::dlsym_load_prefixed(strlen_fn, handle, "str", "len"), 0);
  ASSERT_TRUE(strlen_fn != nullptr);
  ASSERT_EQ(strlen_fn("abcd"), 4u);

  puts_fn_t puts_fn = nullptr;
  xio_rdma::dlsym_load_prefixed_optional(puts_fn, handle, "pu", "ts");
  ASSERT_TRUE(puts_fn != nullptr);

  puts_fn_t missing = reinterpret_cast<puts_fn_t>(0x1);
  xio_rdma::dlsym_load_prefixed_optional(missing, handle, "missing_", "symbol");
  ASSERT_TRUE(missing == nullptr);

  dlclose(handle);
  return 0;
}

int test_dv_dlopen() {
  const char* extra_paths[] = {"/does/not/exist"};
  void* handle = xio_rdma::dv_dlopen("libc.so.6", "unit-test", extra_paths, 1);
  ASSERT_TRUE(handle != nullptr);
  dlclose(handle);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_dlsym_load();
  failures += test_dlsym_load_optional();
  failures += test_dlsym_load_prefixed();
  failures += test_dv_dlopen();

  if (failures == 0) {
    printf("All rdma-check helper tests passed.\n");
    return 0;
  }
  printf("%d rdma-check helper test(s) failed.\n", failures);
  return 1;
}
