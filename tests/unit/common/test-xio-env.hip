/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio::getEnvInt() and xio::getEnvStr() environment helpers.
 * These functions are pure CPU helpers that wrap getenv() with parsing and
 * default-value semantics. Tests use setenv/unsetenv to drive them.
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <hip/hip_runtime.h>

#include "xio-env.h"
#include "xio-test-assert.h"

namespace {

constexpr const char* kEnvName = "ROCXIO_TEST_ENV_VAR";

void clear_env() {
  unsetenv(kEnvName);
}

void set_env(const char* value) {
  setenv(kEnvName, value, 1);
}

} // namespace

int test_getEnvInt_unset_returns_default() {
  clear_env();
  ASSERT_EQ(xio::getEnvInt(kEnvName, 42), 42);
  ASSERT_EQ(xio::getEnvInt(kEnvName, -7), -7);
  ASSERT_EQ(xio::getEnvInt(kEnvName, 0), 0);
  return 0;
}

int test_getEnvInt_empty_returns_default() {
  set_env("");
  ASSERT_EQ(xio::getEnvInt(kEnvName, 99), 99);
  clear_env();
  return 0;
}

int test_getEnvInt_valid_decimal() {
  set_env("0");
  ASSERT_EQ(xio::getEnvInt(kEnvName, -1), 0);
  set_env("1");
  ASSERT_EQ(xio::getEnvInt(kEnvName, -1), 1);
  set_env("123456");
  ASSERT_EQ(xio::getEnvInt(kEnvName, -1), 123456);
  set_env("-1");
  ASSERT_EQ(xio::getEnvInt(kEnvName, 999), -1);
  set_env("-42");
  ASSERT_EQ(xio::getEnvInt(kEnvName, 999), -42);
  clear_env();
  return 0;
}

int test_getEnvInt_invalid_returns_default() {
  set_env("abc");
  ASSERT_EQ(xio::getEnvInt(kEnvName, 17), 17);
  set_env("12abc");
  ASSERT_EQ(xio::getEnvInt(kEnvName, 17), 17);
  set_env("0x10");
  ASSERT_EQ(xio::getEnvInt(kEnvName, 17), 17);
  set_env(" 5");
  /* strtol consumes leading whitespace, so " 5" parses as 5 then
   * succeeds because the trailing char is NUL. This is allowed
   * behaviour and matches getEnvInt's documented contract. */
  ASSERT_EQ(xio::getEnvInt(kEnvName, 17), 5);
  set_env("5 ");
  /* Trailing space is a non-NUL terminator, so parsing fails. */
  ASSERT_EQ(xio::getEnvInt(kEnvName, 17), 17);
  clear_env();
  return 0;
}

int test_getEnvStr_unset_returns_default() {
  clear_env();
  ASSERT_STREQ(xio::getEnvStr(kEnvName, "fallback"), "fallback");
  ASSERT_TRUE(xio::getEnvStr(kEnvName, nullptr) == nullptr);
  return 0;
}

int test_getEnvStr_empty_returns_default() {
  set_env("");
  ASSERT_STREQ(xio::getEnvStr(kEnvName, "fallback"), "fallback");
  clear_env();
  return 0;
}

int test_getEnvStr_returns_value() {
  set_env("hello world");
  ASSERT_STREQ(xio::getEnvStr(kEnvName, "fallback"), "hello world");
  set_env("/dev/something");
  ASSERT_STREQ(xio::getEnvStr(kEnvName, "fallback"), "/dev/something");
  clear_env();
  return 0;
}

int main() {
  int failures = 0;
  failures += test_getEnvInt_unset_returns_default();
  failures += test_getEnvInt_empty_returns_default();
  failures += test_getEnvInt_valid_decimal();
  failures += test_getEnvInt_invalid_returns_default();
  failures += test_getEnvStr_unset_returns_default();
  failures += test_getEnvStr_empty_returns_default();
  failures += test_getEnvStr_returns_value();

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
