/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio::getEnvInt, xio::getEnvStr, and related helpers.
 */

#include <cstdlib>
#include <cstring>

#include <hip/hip_runtime.h>

#include "xio-env.h"
#include "xio-test-assert.h"

namespace {

constexpr const char* kIntName = "ROCXIO_UNITTEST_GETENV_INT";
constexpr const char* kStrName = "ROCXIO_UNITTEST_GETENV_STR";

void unset_both() {
  unsetenv(kIntName);
  unsetenv(kStrName);
}

} // namespace

int test_getenv_int_unset() {
  unsetenv(kIntName);
  ASSERT_EQ(xio::getEnvInt(kIntName, 42), 42);
  return 0;
}

int test_getenv_int_empty() {
  setenv(kIntName, "", 1);
  ASSERT_EQ(xio::getEnvInt(kIntName, 7), 7);
  unset_both();
  return 0;
}

int test_getenv_int_valid() {
  setenv(kIntName, "-99", 1);
  ASSERT_EQ(xio::getEnvInt(kIntName, 0), -99);
  unset_both();
  return 0;
}

int test_getenv_int_trailing_junk() {
  setenv(kIntName, "123abc", 1);
  ASSERT_EQ(xio::getEnvInt(kIntName, 5), 5);
  unset_both();
  return 0;
}

int test_getenv_int_leading_junk() {
  setenv(kIntName, "x42", 1);
  ASSERT_EQ(xio::getEnvInt(kIntName, 3), 3);
  unset_both();
  return 0;
}

int test_getenv_str_unset() {
  unsetenv(kStrName);
  ASSERT_STREQ(xio::getEnvStr(kStrName, "fallback"), "fallback");
  return 0;
}

int test_getenv_str_empty() {
  setenv(kStrName, "", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrName, "fallback"), "fallback");
  unset_both();
  return 0;
}

int test_getenv_str_present() {
  setenv(kStrName, "hello", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrName, "fallback"), "hello");
  unset_both();
  return 0;
}

int main() {
  unset_both();
  int failures = 0;
  failures += test_getenv_int_unset();
  failures += test_getenv_int_empty();
  failures += test_getenv_int_valid();
  failures += test_getenv_int_trailing_junk();
  failures += test_getenv_int_leading_junk();
  failures += test_getenv_str_unset();
  failures += test_getenv_str_empty();
  failures += test_getenv_str_present();

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
