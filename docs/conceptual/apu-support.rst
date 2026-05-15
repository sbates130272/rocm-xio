.. meta::
  :description: Design proposal for adding AMD APU support
    (Strix Halo gfx1151 and other gfx115x / gfx110x APUs) to ROCm XIO
  :keywords: ROCm, XIO, APU, Strix Halo, gfx1151, gfx1150, gfx1103,
    Phoenix, Hawk Point, integrated GPU, UMA, design

.. _apu-support:

************************************************************
Design proposal: APU support (Strix Halo and other AMD APUs)
************************************************************

.. note::

   This page is a **design proposal**, not a description of shipped
   behavior. ROCm XIO currently targets discrete AMD GPUs (CDNA
   Instinct and discrete RDNA Radeon). APU support is not yet
   implemented. This document describes how to extend ROCm XIO so
   that AMD APUs -- Strix Halo (``gfx1151``), Strix Point
   (``gfx1150``), Phoenix and Hawk Point (``gfx1103``), Krackan
   (``gfx1152``), and future APU SKUs -- can be first-class XIO
   targets.

   The goal of the proposal is to make every interface change visible
   before any implementation lands, in line with the project
   "interface-first development" rule.

Motivation
==========

APUs are an important new deployment surface for ROCm XIO:

- **Edge inference and AI PCs.** Strix Halo systems pair a Zen 5 CPU
  with a 40-CU RDNA 3.5 iGPU and up to 128 GiB of unified memory.
  Driving NVMe and RDMA traffic from ``__device__`` code lets the
  iGPU stream model weights and KV-cache pages without round-tripping
  through a host-side loader.
- **Development hardware.** Strix Point and Phoenix laptops are
  inexpensive bring-up vehicles for GDA / RDMA-EP work on RDNA-family
  ISAs that match recent and future discrete RDNA dGPUs.
- **GPU-direct from carve-out memory.** APUs expose framebuffer
  carve-out and GTT pools that already live in system DRAM. Once the
  HSA region and dmabuf paths are taught to handle that geometry,
  GPU-initiated IO becomes a property of the platform rather than of
  a discrete GPU card.

The challenge is that almost every assumption that the rest of the
library makes about "the GPU" is a discrete-GPU assumption. The
allocator assumes a separate VRAM region; the dmabuf export path
assumes a VRAM BAR; the SDMA endpoint targets the CDNA OSS engines
in the MI300X / MI350X family; the doorbell-fence ISA is gated on a
hard-coded list of ``__gfx10**`` / ``__gfx11**`` macros that does
not include ``__gfx1150__`` or ``__gfx1151__``; the kernel module
walks the PCI tree looking for the first AMD device and treats its
BAR0 as a VRAM aperture; and the Debian multi-arch package list and
all GitHub Actions CI legs are gfx942-only.

APUs that this proposal targets
================================

The proposal explicitly enumerates the APU SKUs that ROCm XIO should
build for. Each entry pairs a marketing name with the
``rocm_agent_enumerator`` GFX identifier and the LLVM target macro
that HIP defines inside ``__device__`` code.

.. list-table:: Initial APU target matrix
   :header-rows: 1
   :widths: 25 18 18 39

   * - Family
     - GFX target
     - LLVM macro
     - Notes
   * - Strix Halo (Ryzen AI MAX)
     - ``gfx1151``
     - ``__gfx1151__``
     - RDNA 3.5, up to 40 CU, up to 128 GiB UMA
   * - Strix Point / Krackan
     - ``gfx1150`` / ``gfx1152``
     - ``__gfx1150__`` / ``__gfx1152__``
     - RDNA 3.5, mobile, smaller iGPU
   * - Phoenix / Hawk Point
     - ``gfx1103``
     - ``__gfx1103__``
     - RDNA 3, prior generation, common dev HW
   * - Future RDNA APUs
     - ``gfx12xx`` (Medusa / etc.)
     - ``__gfx12xx__``
     - Use GFX12 doorbell-fence branch

For the rest of this document "APU" means an AMD HSA agent whose
backing memory pools are CPU-attached UMA pools (a single fine-grained
system pool, plus optional carve-out / GTT pools) and whose
``hipDeviceProp_t::integrated`` field is non-zero.

High-level design
=================

The proposal introduces a single internal abstraction --
``xio::AgentTopology`` -- that classifies each HSA agent at startup
and routes per-agent decisions through a small set of strategy
points. Every site that currently hard-codes a discrete-GPU
assumption either consumes ``AgentTopology`` directly or accepts a
``gpuId`` and delegates to ``AgentTopology::for_gpu(gpuId)``.

The new types live in ``src/common/xio-agent-topology.hpp`` and the
implementation in ``src/common/xio-agent-topology.cpp``. They are
host-only (no ``__device__`` code), C++17, and depend only on HIP
and HSA host APIs.

Proposed interface (host-only, header-level)
--------------------------------------------

.. code-block:: cpp

   namespace xio {

   enum class AgentClass : uint8_t {
     Unknown   = 0,
     DiscreteGpu = 1,
     IntegratedGpu = 2,
   };

   enum class MemoryPoolKind : uint8_t {
     Unknown          = 0,
     VramFineGrained  = 1,
     VramCoarseGrained= 2,
     SystemFineGrained= 3,
     SystemCoarseGrained = 4,
     CarveOut         = 5,
   };

   struct PoolInfo {
     hsa_amd_memory_pool_t pool;
     MemoryPoolKind        kind;
     size_t                size_bytes;
     uint32_t              flags;
   };

   struct AgentInfo {
     int                   hipDeviceId;
     hsa_agent_t           hsaAgent;
     AgentClass            agentClass;
     char                  gfxName[32];
     uint32_t              llvmTargetId;
     std::vector<PoolInfo> pools;
     bool                  supportsDmabufVram;
     bool                  supportsDmabufSystem;
     bool                  isIntegrated;
   };

   class AgentTopology {
    public:
     static const AgentTopology& instance();
     const AgentInfo& for_gpu(int hipDeviceId) const;
     const AgentInfo* preferred_gpu() const;
     bool any_integrated() const;
     bool any_discrete() const;
   };

   } // namespace xio

The classification rules:

- ``AgentClass::IntegratedGpu`` if either ``hipDeviceProp_t::integrated``
  is non-zero **or** ``HSA_AMD_AGENT_INFO_MEMORY_PROPERTIES`` reports
  an APU and no ``HSA_AMD_SEGMENT_GLOBAL`` pool with the
  ``HSA_AMD_MEMORY_POOL_GLOBAL_FLAG_KERNARG_INIT`` VRAM bit is found.
- ``MemoryPoolKind::SystemFineGrained`` for the canonical APU pool
  exposed to the GPU agent (HSA reports it as a global segment with
  the ``FINE_GRAINED`` flag set and ``HSA_AMD_MEMORY_POOL_INFO_LOCATION``
  equal to ``HSA_AMD_MEMORY_POOL_LOCATION_CPU``).
- ``supportsDmabufVram`` is false on APUs by definition.
  ``supportsDmabufSystem`` is true when ROCm exposes
  ``hsa_amd_portable_export_dmabuf_v2`` with
  ``HSA_AMD_DMABUF_MAPPING_TYPE_NONE`` for CPU-located pools.

This is the only new interface that callers see. Every existing
public symbol keeps its signature.

Subsystem-by-subsystem proposal
================================

Each subsection lists the affected files, the proposed change, and
the interfaces that must be agreed before code lands. File and line
references are anchored to ``main`` at the time of writing; expect
small drift as the tree evolves.

1. Memory allocator (``src/common/xio-common.hip``)
----------------------------------------------------

The current ``allocDeviceMemoryHsa`` walks ``hsa_iterate_agents``,
stops at the first GPU, and chooses the first ``GLOBAL`` region with
``HSA_REGION_GLOBAL_FLAG_FINE_GRAINED`` or ``COARSE_GRAINED``. On an
APU this picks the system pool, which is correct, but the code logs
"Using HSA fine-grained global memory region" without distinguishing
"VRAM fine" from "system fine," and it ignores the caller's
``gpuId`` argument. That makes multi-agent systems (a Strix Halo
laptop with an external dGPU dock) ambiguous.

Proposed change:

- Add a new internal helper ``selectDevicePool(int gpuId, unsigned
  flags) -> hsa_amd_memory_pool_t`` that consults ``AgentTopology``.
- Route ``allocDeviceMemoryHsa`` and ``allocDeviceMemory`` through
  ``selectDevicePool``. Honor ``gpuId`` properly (today
  ``allocDeviceMemoryHsa`` ignores it).
- When the selected pool is ``SystemFineGrained`` (APU case),
  ``XIO_DEVICE_MEM_UNCACHED`` falls back to
  ``hipExtMallocWithFlags(hipDeviceMallocUncached)`` against the
  system pool. The current path silently does the same thing, but
  the proposal makes the substitution explicit and logs it once per
  process.
- Replace user-facing strings that say "VRAM" with "device memory
  (VRAM)" or "device memory (UMA)" depending on
  ``AgentInfo::agentClass``.

No public API change. The ``XIO_DEVICE_MEM_*`` flag enum stays
binary-compatible. ``XIO_DEVICE_MEM_VMEM`` continues to use
``hipMemCreate``; the HIP virtual memory management path already
works on APUs because it asks for the device-local pool by location
ID, which on an APU resolves to the system pool.

2. DMA-BUF export (``exportDmabuf`` and call sites)
----------------------------------------------------

``exportDmabuf`` in ``src/common/xio-common.hip`` and its three call
sites -- ``IBVWrapper::reg_mr`` (``src/common/ibv-wrapper.cpp``),
``exportRegVramBuf`` (``src/common/xio-common.hip``), and the BNXT
backend (``src/endpoints/rdma-ep/bnxt/bnxt-backend.cpp``) -- assume
the exported buffer is VRAM with a stable PCI bus address. On APUs,
the buffer is a system-RAM page, the dmabuf still works, but the
kernel-side P2PDMA attach in ``kernel/rocm-xio/rocm-xio.c`` cannot
treat it as a VRAM-BAR offset.

Proposed change:

- Rename ``exportRegVramBuf`` to ``exportRegGpuBuf`` and add a
  thin compatibility shim so existing external callers (if any)
  continue to link. The internal callers move to the new name.
- Add an explicit ``MemoryPoolKind`` parameter (or pass the
  ``AgentInfo*``) so the call site does not have to re-classify the
  buffer.
- For ``MemoryPoolKind::SystemFineGrained`` and ``CarveOut``, use
  ``hsa_amd_portable_export_dmabuf_v2`` with
  ``HSA_AMD_DMABUF_MAPPING_TYPE_NONE``. The PCIe mapping type is
  only meaningful for true VRAM apertures.
- Update :ref:`memory-modes` to describe the four-way matrix of
  (host pinned, host coherent, device VRAM, device system) explicitly.

3. Kernel module (``kernel/rocm-xio/rocm-xio.c``)
--------------------------------------------------

The current module:

- Looks up "the AMD GPU" with ``pci_get_device(PCI_VENDOR_ID_ATI,
  PCI_ANY_ID, NULL)``. On an APU laptop this finds the iGPU function
  0, which is fine for the dmabuf case. On a Strix Halo + eGPU dock
  it picks the wrong device.
- Has helpers like ``extract_vram_offset_from_amdgpu_bo`` and
  ``get_dmabuf_bar_gpa`` that assume the BO is backed by TTM VRAM.
  An APU dmabuf is backed by GTT / shmem and goes through a different
  TTM placement.

Proposed change:

- Add a small ``struct rocxio_gpu_target`` registry. The userspace
  side passes a GPU PCI BDF (already available from
  ``hipDeviceGetPCIBusId``) in the ``ROCM_XIO_REGISTER_BUFFER`` and
  ``ROCM_XIO_REGISTER_QUEUE_ADDR`` ioctls. The kernel module looks
  up the exact ``pci_dev`` instead of taking the first match.
- Add a ``ROCM_XIO_CAP_UMA`` flag on the
  ``ROCM_XIO_REGISTER_BUFFER`` request. When set, the module
  resolves the dmabuf without going through
  ``extract_vram_offset_from_amdgpu_bo``: it uses
  ``dma_buf_map_attachment`` and reads the first SG entry's
  ``dma_address`` directly. For NVMe P2PDMA targets this returns the
  IOMMU IOVA assigned to the system page, which is exactly what NVMe
  needs.
- Keep the existing VRAM path for discrete GPUs unchanged. The new
  path is additive.

This is the most invasive change in the proposal. It must be agreed
on as an ioctl ABI extension before any code lands, because shipping
DKMS kernel modules cannot easily revoke ioctl behaviors.

4. SDMA endpoint (``src/endpoints/sdma-ep/``)
---------------------------------------------

The SDMA endpoint currently ships two packet tables: the pre-OSS7
table (CDNA3 / MI300X / ``gfx942``) and the OSS7 table (CDNA4 /
MI350X / ``gfx950``). ``_SDMA_OSS7_TARGETS`` in ``CMakeLists.txt``
contains only ``gfx950``.

RDNA 3.5 APUs ship an SDMA engine, but its packet layout and queue
ABI track the upstream amdgpu kernel-mode driver's RDNA path, not
the CDNA path. The proposal does **not** attempt to make
``sdma-ep`` work on APUs in this pass.

Proposed change:

- Add a new ``apu`` skip predicate to ``XIOTestHelpers.cmake`` so
  ``sdma-ep`` CTest labels are skipped when the active agent is an
  APU. The endpoint compiles cleanly but the tests report ``SKIPPED:
  sdma-ep does not yet support APU SDMA queues``.
- Document the gap explicitly in
  ``docs/reference/endpoints.rst`` so users know that ``rdma-ep``,
  ``nvme-ep``, and ``test-ep`` are the supported endpoints on APUs.
- Track the SDMA-on-RDNA enablement work in a follow-up issue
  separate from this proposal.

5. Doorbell fencing (``src/include/xio.h``)
--------------------------------------------

``ringDoorbellFenced`` has three ISA branches: GFX12
(``__gfx1200__`` / ``__gfx1201__``), the RDNA 2/3 list
(``__gfx1010__`` ... ``__gfx1102__``), and a ``#else`` fallback.
APU GFX targets ``gfx1150``, ``gfx1151``, ``gfx1152``, and
``gfx1103`` are not in either list. ``gfx1103`` is RDNA 3 and uses
the gfx11 instruction encoding. ``gfx1150``/``1151``/``1152`` are
RDNA 3.5 but in LLVM terms still use the gfx11-class wait/cache
mnemonics (``s_waitcnt``, ``buffer_gl1_inv``, ``buffer_gl0_inv``).

Proposed change:

- Extend the RDNA 2/3 branch to:

  .. code-block:: cpp

     #elif __gfx1010__ || __gfx1030__ || __gfx1031__ ||              \
       __gfx1032__ || __gfx1100__ || __gfx1101__ || __gfx1102__ ||   \
       __gfx1103__ || __gfx1150__ || __gfx1151__ || __gfx1152__

- Keep the GFX12 branch and the ``#else`` fallback unchanged.
- Add a comment that calls out which entries are dGPU vs APU so the
  list stays auditable as new RDNA SKUs appear.

This is a pure additive change. No interface impact.

6. Build system (``CMakeLists.txt``, ``cmake/``, ``debian/``)
-------------------------------------------------------------

- ``OFFLOAD_ARCH`` auto-detection in ``CMakeLists.txt`` already
  works on APU systems because ``rocminfo`` reports
  ``gfx1151`` / ``gfx1150`` / ``gfx1103`` correctly. The proposal
  keeps that path and adds an explicit ``XIO_APU_DEFAULT_ARCH``
  cache variable as a hint for CI containers.
- ``DEB_OFFLOAD_ARCH`` in ``debian/rules`` becomes
  ``gfx908:xnack+;gfx90a:xnack+;gfx942:xnack+;gfx950:xnack+;
  gfx1103;gfx1150;gfx1151;gfx1152;gfx1201``. The list is long but
  each entry is a separate per-arch HSACO blob, packaged via
  ``XIO_USE_KPACK``.
- ``cmake/XIODetectGPUs.cmake`` keeps counting agents but tags each
  one as APU vs dGPU in the generated ``ctest-resources.json`` so
  CTest can pick an APU resource for APU-only test labels.

7. Test infrastructure
----------------------

Files: ``tests/``, ``scripts/test/``,
``cmake/XIOTestHelpers.cmake``.

- Add an APU-aware skip helper:
  ``xio_add_test_apu_skip(<test-name> REASON "...")`` that wraps
  ``set_tests_properties(... SKIP_REGULAR_EXPRESSION ...)``.
- The RDMA loopback fixture in
  ``scripts/test/setup-rdma-loopback.sh`` is unaffected: it operates
  on the NIC, not on the GPU.
- The NVMe fixture is unaffected: it operates on the NVMe namespace.
- Add ``tests/system/apu/`` with a single smoke test that allocates
  a 4 MiB ``XIO_DEVICE_MEM_HIP`` buffer, fills it from a kernel,
  exports it as dmabuf, and confirms ``getPhysAddr`` returns a
  non-zero IOVA. This is the minimum end-to-end assertion that
  proves the new path works on real Strix Halo hardware.

8. CI workflows (``.github/workflows/``)
----------------------------------------

CI does not have APU runners today and the proposal does not assume
they will appear. Instead:

- ``build-check.yml`` gains a second matrix leg that compiles with
  ``OFFLOAD_ARCH=gfx1151`` (and the rest of the APU list) to catch
  compile-time regressions on the doorbell fence ISA branches and
  the kernel-module DKMS sources. The leg does **not** run CTest.
- ``test-emulate.yml`` is unchanged. It already runs ``test-ep
  --emulate`` only, which is GPU-agnostic.
- ``deb-build.yml`` consumes the extended ``DEB_OFFLOAD_ARCH``
  default so the released DEBs ship APU HSACO blobs without manual
  intervention.

9. Documentation
----------------

- This page is added to ``docs/sphinx/_toc.yml.in`` under
  *Conceptual*.
- ``docs/conceptual/memory-modes.rst`` gains a short "APU UMA" note
  pointing here.
- ``docs/install/building.rst`` adds ``gfx1151`` to the list of
  example ``OFFLOAD_ARCH`` values.
- ``docs/reference/endpoints.rst`` adds a row to its support matrix
  showing which endpoints work on APUs.
- ``INSTALL.md`` adds a sentence under *Supported hardware* listing
  the APU targets above.
- The ``.wordlist.txt`` gains ``Strix``, ``Halo``, ``Krackan``,
  ``Phoenix``, ``Hawk``, ``Medusa``, ``iGPU``, ``UMA``, ``carveout``.

Open questions
==============

The following questions need explicit answers before implementation
begins. They are listed in priority order.

#. **Kernel ioctl ABI.** Is it acceptable to extend
   ``ROCM_XIO_REGISTER_BUFFER`` with a new flag bit
   (``ROCM_XIO_CAP_UMA``) and a new ``gpu_bdf`` field, gated behind a
   bumped ``ROCM_XIO_IOCTL_VERSION``? Or should the APU path use a
   new ioctl number to keep the dGPU path bit-identical?
#. **NVMe P2PDMA on APUs.** On Strix Halo the NVMe namespace lives
   on an M.2 slot that hangs off the same IOMMU domain as the iGPU.
   Has ``CONFIG_PCI_P2PDMA`` been validated against APU dmabufs in
   any kernel >= 6.10? If not, the APU NVMe path may have to fall
   back to bounce buffers and the proposal should call that out
   explicitly.
#. **HSA pool selection on multi-agent systems.** When a Strix Halo
   laptop is docked with an external Radeon dGPU, both agents are
   present. ``AgentTopology::preferred_gpu()`` needs a tie-breaker.
   The proposal currently prefers the agent that owns the largest
   pool that matches the requested ``XIO_DEVICE_MEM_*`` flags, but
   the user may prefer to pin via ``HIP_VISIBLE_DEVICES``.
#. **Doorbell fence aggressiveness on APUs.** RDNA 3.5 iGPUs share
   L2 with the CPU's IO fabric. The gfx11-style
   ``buffer_gl1_inv`` / ``buffer_gl0_inv`` invalidations may be
   unnecessary on UMA, or they may be the only way to flush write
   combine buffers on the integrated DMA path. We need to measure
   on real hardware before committing the ISA branch.
#. **kpack arch list.** Adding four APU targets to the Debian
   multi-arch package noticeably increases the ``.so`` size. Should
   we keep the default list lean (CDNA + ``gfx1151`` only) and
   require an opt-in for ``gfx1103`` / ``gfx1150`` / ``gfx1152``?

Phasing
=======

The implementation is naturally split into stages that can land
independently. Each stage is a separate PR. Stages 1--4 are pure
additions; stage 5 touches the kernel ioctl ABI and is the only
backwards-incompatible piece.

#. Stage 1: ``ringDoorbellFenced`` ISA branch and ``OFFLOAD_ARCH``
   plumbing for ``gfx1103`` / ``gfx115x``. Compile-only CI matrix.
#. Stage 2: ``AgentTopology`` introduction. No behavioral change --
   existing call sites that already work continue to work.
#. Stage 3: Allocator routing through ``AgentTopology``, with the
   ``MemoryPoolKind`` log line. APU dmabuf export through
   ``hsa_amd_portable_export_dmabuf_v2``. Skip predicate for
   ``sdma-ep`` on APU agents.
#. Stage 4: Documentation, ``.wordlist.txt``, Debian arch list,
   kpack packaging. End-to-end smoke test target.
#. Stage 5: Kernel module APU dmabuf path and ioctl ABI bump. Held
   until question 1 above is answered.

Non-goals for this proposal
===========================

To keep the scope honest, the following are out of scope. They are
worth doing eventually but not as part of "APU support."

- SDMA-EP on RDNA. The packet structures, queue ABI, and OSS version
  for RDNA SDMA need their own design. Tracked separately.
- MLX5 BlueFlame on APUs. The BF/UAR mapping path uses
  ``hsa_amd_memory_lock_to_pool`` against a GPU pool that an APU
  does not expose. The IONIC and BNXT GDA paths cover the common
  APU use case.
- Windows / WSL2 APU support. ``hsa_amd_portable_export_dmabuf`` is
  Linux-only.
- Multi-iGPU systems. There is no AMD APU with more than one HSA
  GPU agent in 2026, so the proposal assumes one APU per node.

References
==========

- :ref:`memory-modes` -- existing memory allocation and dmabuf
  architecture, with the dGPU mental model that this proposal
  extends.
- ``src/common/xio-common.hip`` -- ``allocDeviceMemoryHsa``,
  ``exportDmabuf``, ``exportRegVramBuf``,
  ``allocateGpuAccessibleBuffer``.
- ``src/include/xio.h`` -- ``ringDoorbellFenced`` ISA branches.
- ``kernel/rocm-xio/rocm-xio.c`` -- ``get_dmabuf_bar_gpa``,
  ``extract_vram_offset_from_amdgpu_bo``.
- ``CMakeLists.txt`` -- ``_SDMA_OSS7_TARGETS``, ``OFFLOAD_ARCH``
  auto-detect, ``XIO_DOORBELL_FENCE_AGGRESSIVE``.
- ``debian/rules`` -- ``DEB_OFFLOAD_ARCH``.

.. _ROCm GPU support matrix: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html
.. _LLVM AMDGPUUsage gfx115x: https://llvm.org/docs/AMDGPUUsage.html#processors
.. _HSA fine-grain PCIe: https://rocm.docs.amd.com/en/latest/conceptual/gpu-memory.html
