/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for rocm-xio environment variable helpers.
 */

#include <cstdio>
#include <cstdlib>

#include "xio-env.h"
#include "xio-test-assert.h"

static const char* kIntEnv = "ROCXIO_TEST_ENV_INT";
static const char* kStrEnv = "ROCXIO_TEST_ENV_STR";

int test_get_env_int_default_when_unset() {
  unsetenv(kIntEnv);
  ASSERT_EQ(xio::getEnvInt(kIntEnv, 17), 17);
  return 0;
}

int test_get_env_int_default_when_empty() {
  setenv(kIntEnv, "", 1);
  ASSERT_EQ(xio::getEnvInt(kIntEnv, 23), 23);
  unsetenv(kIntEnv);
  return 0;
}

int test_get_env_int_parses_decimal_values() {
  setenv(kIntEnv, "42", 1);
  ASSERT_EQ(xio::getEnvInt(kIntEnv, 0), 42);

  setenv(kIntEnv, "-7", 1);
  ASSERT_EQ(xio::getEnvInt(kIntEnv, 0), -7);
  unsetenv(kIntEnv);
  return 0;
}

int test_get_env_int_rejects_trailing_junk() {
  setenv(kIntEnv, "19ms", 1);
  ASSERT_EQ(xio::getEnvInt(kIntEnv, 5), 5);

  setenv(kIntEnv, "abc", 1);
  ASSERT_EQ(xio::getEnvInt(kIntEnv, 9), 9);
  unsetenv(kIntEnv);
  return 0;
}

int test_get_env_str_default_when_unset_or_empty() {
  unsetenv(kStrEnv);
  ASSERT_STREQ(xio::getEnvStr(kStrEnv, "fallback"), "fallback");

  setenv(kStrEnv, "", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrEnv, "empty-fallback"), "empty-fallback");
  unsetenv(kStrEnv);
  return 0;
}

int test_get_env_str_returns_environment_value() {
  setenv(kStrEnv, "rocm-xio", 1);
  ASSERT_STREQ(xio::getEnvStr(kStrEnv, "fallback"), "rocm-xio");
  unsetenv(kStrEnv);
  return 0;
}

int main() {
  int failures = 0;
  failures += test_get_env_int_default_when_unset();
  failures += test_get_env_int_default_when_empty();
  failures += test_get_env_int_parses_decimal_values();
  failures += test_get_env_int_rejects_trailing_junk();
  failures += test_get_env_str_default_when_unset_or_empty();
  failures += test_get_env_str_returns_environment_value();

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
