# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

if(NOT DEFINED CMAKE_PREFIX_PATH OR CMAKE_PREFIX_PATH STREQUAL "")
  message(FATAL_ERROR "CMAKE_PREFIX_PATH is required")
endif()

set(_prefix "${CMAKE_PREFIX_PATH}")
set(_required_files
  "${_prefix}/include/rocm-xio/xio.h"
  "${_prefix}/include/rocm-xio/xio-endpoint-core.h"
  "${_prefix}/include/rocm-xio/xio-endpoint-registry.h"
  "${_prefix}/lib/cmake/rocm-xio/rocm-xio-config.cmake"
  "${_prefix}/lib/cmake/rocm-xio/rocm-xio-targets.cmake"
)

foreach(_file IN LISTS _required_files)
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR
      "Expected install artifact is missing: ${_file}")
  endif()
endforeach()

message(STATUS "Install layout validation passed: ${_prefix}")
