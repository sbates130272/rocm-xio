# ROCm XIO fio Ansible role

This directory contains a focused Ansible workflow for the ROCm XIO/FIO
integration branches.  It installs the `rocm-xio` branch that exposes the
persistent NVMe session API, builds the FIO fork branch that adds the
`rocm_xio` ioengine, and runs build-time and optional hardware checks.

## Branch review notes

- The ROCm XIO branch is `dev/stebates/nvme-ep-fio-api` in the
  [ROCm XIO fork][rocm-xio-fork].  It adds persistent NVMe session calls,
  including `openPersistentSession`, `postPersistent`, `reapPersistent`, and
  persistent-worker phase counters.
- The FIO fork does not have a branch named exactly `rocm-xio`.  The branch
  that matches the ROCm XIO API is `dev/batesste/rocm-xio-engine` in the
  [FIO fork][fio-fork].  It adds `engines/rocm_xio.c`, a C++ shim, configure
  detection, and an example job file.
- The FIO engine uses FIO buffers for scheduling and accounting, but the data
  path uses ROCm XIO's persistent read/write buffers.  FIO's normal data
  verification patterns are therefore not a drop-in fit; use the engine's
  `rocm_xio_verify_lfsr` option when verification is needed.
- A real hardware run requires a ROCm-capable AMD GPU, a non-root NVMe
  namespace, the `rocm-xio` kernel module, and root privileges for NVMe queue
  management.

## What the role does

The `rocm_xio_fio` role performs these steps on an Ubuntu host:

1. Installs build dependencies and the matching kernel headers.
2. Clones the ROCm XIO and FIO fork branches into a managed workspace.
3. Configures, builds, and installs ROCm XIO with `INSTALL_TESTER=ON`.
4. Builds and loads the `rocm-xio` kernel module.
5. Installs ROCm XIO udev rules.
6. Configures and builds FIO with `--with-rocm-xio=<install-prefix>`.
7. Runs `./fio --enghelp=rocm_xio` as a non-destructive smoke test.
8. Optionally renders and runs a read-only ROCm XIO FIO hardware job.

The hardware job is disabled by default.  Enable it only on a host where the
selected namespace is safe to test.  Write-like FIO modes require the explicit
`rocm_xio_fio_allow_destructive_test=true` guard.

## Example inventory

```ini
[rocm_xio_fio]
rocm-host ansible_host=192.0.2.10 ansible_user=ubuntu
```

## Build and smoke-test only

```bash
ansible-playbook -i inventory.ini ansible/playbooks/rocm-xio-fio.yml
```

## Build and run a read-only hardware test

```bash
ansible-playbook -i inventory.ini ansible/playbooks/rocm-xio-fio.yml \
  -e rocm_xio_fio_run_hardware_test=true \
  -e rocm_xio_fio_test_filename=/dev/disk/by-id/nvme-MTR_SLC_16GB_0400000E3CBC
```

The default job uses `rw=randread`, `bs=512`, `iodepth=64`, queue ID 28, and
ROCm XIO memory mode 0.  Override the variables in
`ansible/roles/rocm_xio_fio/defaults/main.yml` to match the target host.

<!-- References -->

[fio-fork]: https://github.com/sbates130272/fio
[rocm-xio-fork]: https://github.com/sbates130272/rocm-xio
