<!--
Copyright (c) Advanced Micro Devices, Inc. All rights reserved.

SPDX-License-Identifier: MIT
-->

# rocm_xio_fio

Build and install the `rocm_xio` fio engine against an installed `rocm-xio`
prefix, then run a safe engine-discovery smoke test. The role can also render
and run a small NVMe fio job, but that path is disabled by default because it
can issue I/O to the target namespace.

## Default flow

1. Build and install `rocm-xio` headers and `librocm-xio.so`.
2. Clone the fio fork branch with the `rocm_xio` engine.
3. Configure fio with `--enable-rocm-xio` and `--with-rocm-xio`.
4. Build and optionally install fio.
5. Run `fio --enghelp=rocm_xio`.

Set `rocm_xio_fio_run_nvme_smoke=true` and provide
`rocm_xio_fio_nvme_filename` to run the generated fio job.
