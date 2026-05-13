# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.21)
project(package-headers-test LANGUAGES CXX HIP)

find_package(rocm-xio REQUIRED)

add_executable(package-headers main.cpp)
target_link_libraries(package-headers PRIVATE rocm-xio::rocm-xio)
