/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio::getEnvInt and xio::getEnvStr (xio-env.h). Uses
 * unique variable names so parallel ctest workers do not collide.
 */

#include <cstdio>
#include <cstdlib>

#include <hip/hip_runtime.h>

#include "xio-env.h"
#include "xio-test-assert.h"

static const char kIntVar[] = "ROCXIO_UNITTEST_ENV_INT";
static const char kStrVar[] = "ROCXIO_UNITTEST_ENV_STR";

int test_get_env_int_unset() {
  unsetenv(kIntVar);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 7), 7);
  return 0;
}

int test_get_env_int_empty() {
  setenv(kIntVar, "", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 8), 8);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_int_valid() {
  setenv(kIntVar, "-42", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 0), -42);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_int_invalid() {
  setenv(kIntVar, "12abc", 1);
  ASSERT_EQ(xio::getEnvInt(kIntVar, 99), 99);
  unsetenv(kIntVar);
  return 0;
}

int test_get_env_str_unset() {
  unsetenv(kStrVar);
  ASSERT_STREQ(xio::getEnvStr(kStrVar, "fallback"), "fallback");
  return 0;
}

int test_get_env_str_empty() {
  setenv(kStrVar, "", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrVar, "fb"), "fb");
  unsetenv(kStrVar);
  return 0;
}

int test_get_env_str_set() {
  setenv(kStrVar, "hello", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrVar, "fb"), "hello");
  unsetenv(kStrVar);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_get_env_int_unset();
  failures += test_get_env_int_empty();
  failures += test_get_env_int_valid();
  failures += test_get_env_int_invalid();
  failures += test_get_env_str_unset();
  failures += test_get_env_str_empty();
  failures += test_get_env_str_set();
  if (failures == 0) {
    printf("All xio-env helper tests passed.\n");
    return 0;
  }
  printf("%d xio-env helper test(s) failed.\n", failures);
  return 1;
}
