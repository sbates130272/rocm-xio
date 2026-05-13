/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio environment helpers.
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "xio-env.h"
#include "xio-test-assert.h"

int test_get_env_int_defaults() {
  unsetenv("ROCXIO_TEST_INT");
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_INT", 42), 42);

  setenv("ROCXIO_TEST_INT", "", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_INT", 99), 99);
  return 0;
}

int test_get_env_int_parse() {
  setenv("ROCXIO_TEST_INT", "1234", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_INT", 7), 1234);

  setenv("ROCXIO_TEST_INT", "12x", 1);
  ASSERT_EQ(xio::getEnvInt("ROCXIO_TEST_INT", 7), 7);
  return 0;
}

int test_get_env_str() {
  unsetenv("ROCXIO_TEST_STR");
  ASSERT_STREQ(xio::getEnvStr("ROCXIO_TEST_STR", "default"), "default");

  setenv("ROCXIO_TEST_STR", "enabled", 1);
  ASSERT_STREQ(xio::getEnvStr("ROCXIO_TEST_STR", "default"), "enabled");
  return 0;
}

int test_log_level_with_verbose_floor() {
  setenv("ROCXIO_VERBOSE", "1", 1);
  setenv("ROCXIO_LOG_LEVEL", "1", 1);

  ASSERT_TRUE(xio::rocxioVerbose());
  ASSERT_EQ(xio::rocxioLogLevel(), static_cast<int>(xio::LOG_INFO));
  return 0;
}

int main() {
  int failures = 0;
  failures += test_get_env_int_defaults();
  failures += test_get_env_int_parse();
  failures += test_get_env_str();
  failures += test_log_level_with_verbose_floor();

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
