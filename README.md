# Astrelm OS

**Astrelm is an operating system for autonomous machines that must keep doing useful work as their hardware and environment degrade.**

Its goal is to preserve the **best remaining chance of future mission success**.

Targets include remote weather stations, drones, rovers, robots, boats, and spacecraft: systems that may run unattended for months or years and cannot assume a human can repair them.

Astrelm treats the machine as a set of resources whose advertised properties can change over time. A resource is not merely working or failed: it may still provide useful service with less capacity, lower quality, worse timing, reduced confidence, or intermittent availability.

## Building the first image

The initial target is **riscv64 / virt / minimal**: QEMU's RV64 `virt` machine and a
payload package containing one compile-only application. The build produces linked RISC-V
ELF files and three ext2 partition images. The system ELF boots directly with QEMU's
default OpenSBI firmware and prints `Hello, world!` over serial. **The partition images
do not boot yet.** There is no application loader, filesystem driver, partition table,
or A/B slot handling.

Host tools: CMake 3.24+, Ninja, LLVM Clang with RISC-V support, LLD (`ld.lld`),
and e2fsprogs (`mke2fs`). Image creation uses ordinary files and requires no mounts or root.
On macOS, the standard Homebrew LLVM, LLD, and e2fsprogs locations are also searched.
Tools can be selected with `CC`, `CXX`, `LD_LLD`, and `MKE2FS` on the first build; CMake
caches their paths for subsequent builds.
Running the system ELF also requires `qemu-system-riscv64`.

```sh
cmake -DASTRELM_ARCH=riscv64 -DASTRELM_BOARD=virt -DASTRELM_PAYLOAD=minimal -P src/build.cmake
```

The checkout remembers that selection in `build/target.json` for subsequent builds:

```sh
cmake -P src/build.cmake
```

Boot the system ELF directly; the ext2 images are not part of this first boot path:

```sh
qemu-system-riscv64 -M virt -m 128M -smp 1 -nographic \
  -bios default \
  -kernel build/riscv64-virt-minimal/src/system/astrelm.elf
```

OpenSBI's banner is followed by `Hello, world!`. Press Ctrl+A, then X to exit QEMU.
The kernel runs in supervisor mode with a small startup stack and writes directly to
the `virt` board's UART0. The compile-only payload does not run yet.

All temporary output lives under the selected triplet:

```text
build/
  target.json
  riscv64-virt-minimal/
    CMakeCache.txt
    build.ninja
    compile_commands.json
    src/system/astrelm.elf
    src/payloads/minimal/minimal.elf
    sysroot/
      system/
        boot/astrelm.elf
      payload/bin/minimal.elf
      data/
    images/
      system.img
      payload.img
      data.img
```

Each partition is currently **8 MiB**. System and payload images contain their staged
files; the data image starts empty apart from filesystem metadata. These are standalone
partition images, not a combined flashable disk image. The staged sysroot is generated
output; change install rules or sources rather than editing it directly. Deleting `build/`
removes all output and the saved checkout selection.

## Source layout

All source files live under `src/`. Build configuration is under `config/`, while
kernel implementation is contained in `system/kernel/`:

```text
src/
  build.cmake
  config/
    arch/riscv64/toolchain.cmake
    boards/virt/
      board.cmake
      image.cmake
  system/
    includes/
    config/
    kernel/
      main.cpp
      arch/riscv64/boot.S
      boards/virt/
        system.ld
        uart.cpp
  payloads/
    CMakeLists.txt
    minimal/
      CMakeLists.txt
      apps/minimal/main.cpp
```

The existing `system/includes/` and `system/config/` directories remain available for
system headers and runtime configuration. A board configuration declares its supported
architectures, kernel sources, linker script, and image assembly steps. Architecture
configuration supplies the toolchain; kernel startup code lives under `system/kernel/arch/`.

A **payload is a complete mission package**. It owns the source for its applications,
mission configuration, and package build definition under `src/payloads/<mission>/`.
Its `CMakeLists.txt` defines the executables for that mission and exports them through
`ASTRELM_PAYLOAD_TARGETS`. The package controls its internal source layout; for example,
a weather mission could contain its own sampler and uploader applications alongside
their mission-specific code and configuration.

The build selects the whole package. Common build rules compile its executables with
the target toolchain and install them into `payload/bin/`. The `minimal` package currently
contains one application and can grow to contain several executables. The
`astrelm_payload` build target groups the package's executables.

Only the selected board and mission package enter the build. Unsupported combinations
and invalid exported executable targets are rejected.

Compilation is incremental. Changed binaries or install rules recreate the staged sysroot
and partition images, preventing stale installed files from carrying into an image. Images
use normal ext2 timestamps and UUIDs, so byte-for-byte reproducibility is not promised yet.
