/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for environment parsing helpers in xio-env.
 */

#include <cstdio>
#include <cstdlib>

#include "xio-env.h"
#include "xio-test-assert.h"

int test_get_env_int_unset() {
  unsetenv("ROCXIO_TEST_ENV_INT");
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_ENV_INT", 77), 77);
  return 0;
}

int test_get_env_int_valid() {
  setenv("ROCXIO_TEST_ENV_INT", "123", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_ENV_INT", 0), 123);
  return 0;
}

int test_get_env_int_negative() {
  setenv("ROCXIO_TEST_ENV_INT", "-41", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_ENV_INT", 9), -41);
  return 0;
}

int test_get_env_int_invalid() {
  setenv("ROCXIO_TEST_ENV_INT", "12x", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_ENV_INT", 88), 88);
  return 0;
}

int test_get_env_int_empty() {
  setenv("ROCXIO_TEST_ENV_INT", "", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_ENV_INT", 66), 66);
  return 0;
}

int test_get_env_str_unset() {
  unsetenv("ROCXIO_TEST_ENV_STR");
  ASSERT_STREQ(xio::getEnvStr("ROCXIO_TEST_ENV_STR", "fallback"), "fallback");
  return 0;
}

int test_get_env_str_set() {
  setenv("ROCXIO_TEST_ENV_STR", "rdma-value", 1);
  ASSERT_STREQ(xio::getEnvStr("ROCXIO_TEST_ENV_STR", "fallback"),
               "rdma-value");
  return 0;
}

int test_get_env_str_empty() {
  setenv("ROCXIO_TEST_ENV_STR", "", 1);
  ASSERT_STREQ(xio::getEnvStr("ROCXIO_TEST_ENV_STR", "fallback"), "fallback");
  return 0;
}

int main() {
  int failures = 0;
  failures += test_get_env_int_unset();
  failures += test_get_env_int_valid();
  failures += test_get_env_int_negative();
  failures += test_get_env_int_invalid();
  failures += test_get_env_int_empty();
  failures += test_get_env_str_unset();
  failures += test_get_env_str_set();
  failures += test_get_env_str_empty();

  unsetenv("ROCXIO_TEST_ENV_INT");
  unsetenv("ROCXIO_TEST_ENV_STR");

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
