/* Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Unit tests for xio::getEnvInt() and xio::getEnvStr().
 */

#include <cstdio>
#include <cstdlib>
#include <string>

#include "xio-env.h"
#include "xio-test-assert.h"

namespace {

struct ScopedEnvVar {
  explicit ScopedEnvVar(const char* key) : key_(key) {
    const char* existing = std::getenv(key_);
    hadValue_ = (existing != nullptr);
    if (hadValue_) {
      value_ = existing;
    }
  }

  ~ScopedEnvVar() {
    if (hadValue_) {
      setenv(key_, value_.c_str(), 1);
    } else {
      unsetenv(key_);
    }
  }

  const char* key_;
  bool hadValue_ = false;
  std::string value_;
};

int test_getEnvInt_missing_and_empty() {
  const char* key = "ROCXIO_TEST_ENV_INT_MISSING";
  ScopedEnvVar restore(key);

  unsetenv(key);
  ASSERT_EQ(xio::getEnvInt(key, 17), 17);

  setenv(key, "", 1);
  ASSERT_EQ(xio::getEnvInt(key, 21), 21);
  return 0;
}

int test_getEnvInt_valid_and_invalid() {
  const char* key = "ROCXIO_TEST_ENV_INT_PARSE";
  ScopedEnvVar restore(key);

  setenv(key, "42", 1);
  ASSERT_EQ(xio::getEnvInt(key, 0), 42);

  setenv(key, "-7", 1);
  ASSERT_EQ(xio::getEnvInt(key, 0), -7);

  setenv(key, "0x2A", 1);
  ASSERT_EQ(xio::getEnvInt(key, 99), 99);

  setenv(key, "12junk", 1);
  ASSERT_EQ(xio::getEnvInt(key, 88), 88);
  return 0;
}

int test_getEnvStr_missing_empty_and_value() {
  const char* key = "ROCXIO_TEST_ENV_STR_VALUE";
  ScopedEnvVar restore(key);

  unsetenv(key);
  ASSERT_STREQ(xio::getEnvStr(key, "fallback"), "fallback");

  setenv(key, "", 1);
  ASSERT_STREQ(xio::getEnvStr(key, "fallback2"), "fallback2");

  setenv(key, "bnxt", 1);
  ASSERT_STREQ(xio::getEnvStr(key, "fallback3"), "bnxt");
  return 0;
}

} // namespace

int main() {
  int failures = 0;
  failures += test_getEnvInt_missing_and_empty();
  failures += test_getEnvInt_valid_and_invalid();
  failures += test_getEnvStr_missing_empty_and_value();

  if (failures == 0) {
    printf("All xio-env tests passed.\n");
    return 0;
  }

  printf("%d xio-env test(s) failed.\n", failures);
  return 1;
}
