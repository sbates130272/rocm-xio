/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio environment-variable helpers.
 */

#include <cstdio>
#include <cstdlib>

#include "xio-env.h"
#include "xio-test-assert.h"

int test_get_env_int() {
  const char* key = "ROCXIO_TEST_ENV_INT";
  unsetenv(key);
  ASSERT_EQ(xio::getEnvInt(key, 17), 17);

  setenv(key, "42", 1);
  ASSERT_EQ(xio::getEnvInt(key, 17), 42);

  setenv(key, "-9", 1);
  ASSERT_EQ(xio::getEnvInt(key, 17), -9);

  setenv(key, "12junk", 1);
  ASSERT_EQ(xio::getEnvInt(key, 17), 17);

  setenv(key, "", 1);
  ASSERT_EQ(xio::getEnvInt(key, 17), 17);

  unsetenv(key);
  return 0;
}

int test_get_env_str() {
  const char* key = "ROCXIO_TEST_ENV_STR";
  unsetenv(key);
  ASSERT_STREQ(xio::getEnvStr(key, "fallback"), "fallback");

  setenv(key, "enabled", 1);
  ASSERT_STREQ(xio::getEnvStr(key, "fallback"), "enabled");

  setenv(key, "", 1);
  ASSERT_STREQ(xio::getEnvStr(key, "fallback"), "fallback");

  unsetenv(key);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_get_env_int();
  failures += test_get_env_str();

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
