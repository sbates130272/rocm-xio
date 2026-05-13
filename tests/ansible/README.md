# rocm-xio fio Ansible role

This role builds and installs rocm-xio, the rocm-xio kernel module,
and the fio fork that ships the rocm_xio ioengine. It targets Ubuntu
24.04 hosts that already have the AMD ROCm apt repository configured.

The full feature review that motivated this role lives in the pull
request description; this README only covers running the role.

## What gets installed

- ROCm HIP and HSA development packages (when
  `rocm_xio_install_packages=true`).
- rocm-xio from `https://github.com/ROCm/rocm-xio.git`, branch
  `dev/stebates/nvme-ep-fio-api`, installed under `/opt/rocm`.
- The rocm-xio kernel module, plus the four udev rules under
  `udev/`.
- The fio fork from `https://github.com/sbates130272/fio.git`,
  branch `dev/batesste/rocm-xio-engine`, installed under
  `/usr/local`.

## Quick start

```
cd tests/ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml -i inventory.example.yml
```

The role is idempotent. Re-running with `--tags fio` rebuilds
just the fio half once rocm-xio is in place.

## Smoke test

Set `rocm_xio_run_smoke_test=true` and point
`rocm_xio_smoke_filename` at a disposable NVMe namespace to
exercise the engine end to end. The default job uses
`rw=randread`, `bs=4k`, `iodepth=32`, and `runtime=5s` so it
will not overwrite data.

```
ansible-playbook site.yml \
  -e rocm_xio_run_smoke_test=true \
  -e rocm_xio_smoke_filename=/dev/disk/by-id/nvme-...
```

## Tunables

See `roles/rocm_xio_fio/defaults/main.yml` for every tunable.
The most useful overrides are:

- `rocm_xio_ref` and `fio_ref` to pin sources.
- `rocm_xio_local_src` and `fio_local_src` to skip the clone
  and build from a local checkout.
- `rocm_xio_offload_arch` to set the GPU target (default
  `native`).
- `rocm_xio_build_shared` to switch from the default static
  library to a shared library. Leave this off until the
  rocm-xio persistent NVMe API is decorated with the
  `XIO_API` visibility macro; otherwise the fio shim will
  fail to link.
