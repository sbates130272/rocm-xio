# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT

# Install-integration tests for rocm-xio.
#
# These tests install the library to a temporary prefix
# and then configure, build, and run standalone example
# projects against the installed package.  All tests
# carry the "integration" CTest label.

include(XIOInstallTests)

xio_install_test_fixture()

# Configure-only: verify find_package(rocm-xio) resolves.
xio_add_install_test(
  NAME find-package
  SOURCE_DIR
    ${CMAKE_SOURCE_DIR}/examples/find-package
)

# Compile-only: verify exported target includes and
# endpoint-registry API are usable from an installed package.
xio_add_install_test(
  NAME package-headers
  SOURCE_DIR
    ${CMAKE_CURRENT_SOURCE_DIR}/package-headers
)

# Compile + run: list available endpoints.
xio_add_install_test(
  NAME list-endpoints
  SOURCE_DIR
    ${CMAKE_SOURCE_DIR}/examples/list-endpoints
  RUN
)

# Compile + run: iterate endpoint registry entries.
xio_add_install_test(
  NAME endpoint-info
  SOURCE_DIR
    ${CMAKE_SOURCE_DIR}/examples/endpoint-info
  RUN
)

# Compile-only: SDMA P2P transfer (needs 2 GPUs to run).
xio_add_install_test(
  NAME sdma-ep-p2p
  SOURCE_DIR
    ${CMAKE_SOURCE_DIR}/examples/sdma-ep-p2p
)

# Compile-only: NVMe controller info (needs NVMe device
# and root access to run).
xio_add_install_test(
  NAME nvme-ep-info
  SOURCE_DIR
    ${CMAKE_SOURCE_DIR}/examples/nvme-ep-info
)

# Compile-only: MPI allgather via shader-initiated SDMA
# (needs MPI + N GPUs to run).
find_package(MPI QUIET)
if(MPI_FOUND)
  xio_add_install_test(
    NAME sdma-ep-allgather
    SOURCE_DIR
      ${CMAKE_SOURCE_DIR}/examples/sdma-ep-allgather
  )
endif()
