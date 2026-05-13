/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio-env helpers (getEnvInt, getEnvStr) and optional
 * subprocess checks for rocxioLogLevel() driven by CTest ENVIRONMENT.
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <hip/hip_runtime.h>

#include "xio-env.h"
#include "xio-test-assert.h"

static int test_get_env_int_valid_decimal() {
  setenv("XIO_UT_INT_A", "123", 1);
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_A", 0), 123);
  unsetenv("XIO_UT_INT_A");
  return 0;
}

static int test_get_env_int_negative() {
  setenv("XIO_UT_INT_NEG", "-7", 1);
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_NEG", 0), -7);
  unsetenv("XIO_UT_INT_NEG");
  return 0;
}

static int test_get_env_int_unset_uses_default() {
  unsetenv("XIO_UT_INT_MISSING");
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_MISSING", 42), 42);
  return 0;
}

static int test_get_env_int_empty_uses_default() {
  setenv("XIO_UT_INT_EMPTY", "", 1);
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_EMPTY", 9), 9);
  unsetenv("XIO_UT_INT_EMPTY");
  return 0;
}

static int test_get_env_int_invalid_non_numeric() {
  setenv("XIO_UT_INT_BAD", "not-a-number", 1);
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_BAD", 55), 55);
  unsetenv("XIO_UT_INT_BAD");
  return 0;
}

static int test_get_env_int_trailing_junk_rejected() {
  setenv("XIO_UT_INT_TAIL", "99z", 1);
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_TAIL", 3), 3);
  unsetenv("XIO_UT_INT_TAIL");
  return 0;
}

static int test_get_env_int_leading_whitespace_accepted() {
  setenv("XIO_UT_INT_WS", "  15", 1);
  ASSERT_EQ(xio::getEnvInt("XIO_UT_INT_WS", 0), 15);
  unsetenv("XIO_UT_INT_WS");
  return 0;
}

static int test_get_env_str_unset() {
  unsetenv("XIO_UT_STR_MISSING");
  ASSERT_STREQ(xio::getEnvStr("XIO_UT_STR_MISSING", "fallback"),
               "fallback");
  return 0;
}

static int test_get_env_str_set() {
  setenv("XIO_UT_STR_SET", "hello", 1);
  ASSERT_STREQ(xio::getEnvStr("XIO_UT_STR_SET", "fallback"), "hello");
  unsetenv("XIO_UT_STR_SET");
  return 0;
}

static int test_get_env_str_empty_means_default() {
  setenv("XIO_UT_STR_EMPTY", "", 1);
  ASSERT_STREQ(xio::getEnvStr("XIO_UT_STR_EMPTY", "def"), "def");
  unsetenv("XIO_UT_STR_EMPTY");
  return 0;
}

static int run_expect_log_mode(int argc, char** argv) {
  if (argc < 3 || strcmp(argv[1], "--expect-log") != 0) {
    printf("usage: %s --expect-log <expected-int>\n", argv[0]);
    return 2;
  }
  int want = atoi(argv[2]);
  int got = xio::rocxioLogLevel();
  ASSERT_EQ(got, want);
  printf("rocxioLogLevel() == %d as expected.\n", want);
  return 0;
}

int main(int argc, char** argv) {
  if (argc >= 3 && strcmp(argv[1], "--expect-log") == 0) {
    return run_expect_log_mode(argc, argv);
  }

  int failures = 0;
  failures += test_get_env_int_valid_decimal();
  failures += test_get_env_int_negative();
  failures += test_get_env_int_unset_uses_default();
  failures += test_get_env_int_empty_uses_default();
  failures += test_get_env_int_invalid_non_numeric();
  failures += test_get_env_int_trailing_junk_rejected();
  failures += test_get_env_int_leading_whitespace_accepted();
  failures += test_get_env_str_unset();
  failures += test_get_env_str_set();
  failures += test_get_env_str_empty_means_default();

  if (failures == 0) {
    printf("All xio-env unit tests passed.\n");
    return 0;
  }
  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
