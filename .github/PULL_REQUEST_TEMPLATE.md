<!--
Copyright (c) Advanced Micro Devices, Inc. All rights reserved.

SPDX-License-Identifier: MIT
-->

## Summary

<!--
Describe what this PR changes and *why*.  Keep it focused on the
unique value of the change.  Link any related issue with "Fixes #N"
or "Refs #N".
-->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing
      behavior to change)
- [ ] Documentation only
- [ ] CI / build system / tooling
- [ ] Refactor (no functional change)

## Affected subsystems

<!--
Tick any area that this PR touches.  This helps the reviewer route the
change to the right code owner and pick the right test sweep.
-->

- [ ] Userspace library (`src/`)
- [ ] CLI tester (`xio-tester`)
- [ ] Kernel modules (`kernel/`)
- [ ] Examples (`examples/`)
- [ ] Documentation (`docs/`, `README.md`)
- [ ] Debian packaging (`debian/`)
- [ ] CI workflows (`.github/workflows/`)
- [ ] udev rules (`udev/`)

## Testing

<!--
Describe what you ran.  At minimum the in-tree CTest sweep should
pass; for hardware-touching changes call out which RDMA vendor and
NVMe device were exercised and which suites were skipped.  Paste the
exact commands when possible so the reviewer can reproduce.
-->

- [ ] `ctest --test-dir build --output-on-failure` (non-RDMA)
- [ ] BNXT RDMA sweep
- [ ] Pensando Ionic RDMA sweep
- [ ] NVMe path on the MTR SLC by-id namespace only
- [ ] Documentation build (`cmake --build build --target sphinx-html`)
- [ ] N/A (explain below)

## Checklist

- [ ] My code follows the [STYLEGUIDE](../STYLEGUIDE.md) and
      `clang-format` is clean.
- [ ] I added or updated tests where appropriate.
- [ ] I added or updated documentation where appropriate.
- [ ] I read [CONTRIBUTING.md](../CONTRIBUTING.md).
- [ ] I have **not** used a volatile NVMe namespace path such as
      `/dev/nvme0n1` in any benchmark or destructive command.

## Additional context

<!-- Anything else the reviewer should know. -->
