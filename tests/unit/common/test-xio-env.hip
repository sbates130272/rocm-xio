/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio-env environment parsing helpers.
 */

#include <cstdlib>

#include <hip/hip_runtime.h>

#include "xio-env.h"
#include "xio-test-assert.h"

namespace {

constexpr const char* kIntVar = "ROCXIO_UNITTEST_GETENV_INT";
constexpr const char* kStrVar = "ROCXIO_UNITTEST_GETENV_STR";

} // namespace

int test_get_env_int_unset() {
  unsetenv(kIntVar);
  ASSERT_EQ(xio::getEnvInt(kIntVar, -7), -7);
  return 0;
}

int test_get_env_int_valid() {
  setenv(kIntVar, "42", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 0), 42);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_int_negative() {
  setenv(kIntVar, "-99", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 0), -99);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_int_invalid_returns_default() {
  setenv(kIntVar, "12abc", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 3), 3);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_int_empty_returns_default() {
  setenv(kIntVar, "", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 11), 11);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_str_unset() {
  unsetenv(kStrVar);
  ASSERT_STREQ(xio::getEnvStr(kStrVar, "fallback"), "fallback");
  return 0;
}

int test_get_env_str_set() {
  setenv(kStrVar, "hello", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrVar, "fallback"), "hello");
  unsetenv(kStrVar);
  return 0;
}

int test_get_env_str_empty_returns_default() {
  setenv(kStrVar, "", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrVar, "empty-means-default"),
               "empty-means-default");
  unsetenv(kStrVar);
  return 0;
}

int main() {
  test_get_env_int_unset();
  test_get_env_int_valid();
  test_get_env_int_negative();
  test_get_env_int_invalid_returns_default();
  test_get_env_int_empty_returns_default();
  test_get_env_str_unset();
  test_get_env_str_set();
  test_get_env_str_empty_returns_default();
  printf("test-xio-env: all tests passed\n");
  return 0;
}
