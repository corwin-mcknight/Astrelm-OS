# Building Astrelm OS

Requires CMake 3.24+, Ninja, Python 3, RISC-V capable Clang, `clang-tidy`, `ld.lld`,
and `mke2fs`. Running the kernel requires `qemu-system-riscv64`. If tool discovery
fails, set `CC`, `CXX`, `LD_LLD`, or `MKE2FS` before the first build.

From the repository root:

```sh
cmake -P src/build.cmake
```

The default target is `riscv64-virt-minimal`. To select a target explicitly:

```sh
cmake -DASTRELM_ARCH=riscv64 -DASTRELM_BOARD=virt -DASTRELM_PAYLOAD=minimal -P src/build.cmake
```

The selection is saved in `build/target.json`; output goes to `build/<arch>-<board>-<payload>/`.

The default `size` profile uses `-Os -g`: size-optimized code with source-level debug
information. Use `debug` for `-Og -g3 -fno-omit-frame-pointer`:

```sh
cmake -DASTRELM_PROFILE=debug -P src/build.cmake
```

The selected profile is saved for subsequent builds. Pass `-DASTRELM_PROFILE=size` to
switch back. Switching profiles reconfigures and rebuilds the same target directory.
Both profiles keep `NDEBUG` undefined, so invariant checks are not removed by the
build configuration.

Boot the system ELF directly:

```sh
qemu-system-riscv64 -M virt -m 128M -smp 1 -nographic \
  -bios default \
  -kernel build/riscv64-virt-minimal/src/system/astrelm.elf
```

The kernel prints `Astrelm kernel booting; hart=0`. Exit QEMU with Ctrl+A, then X.

The build also produces `images/system.img`, `images/payload.img`, and `images/data.img` under the target output directory. These are standalone 8 MiB ext2 partitions, not a bootable disk image. The minimal payload is built but does not run yet.

## Static analysis

Every build runs the system-code `clang-tidy` checks against the configured target's
compile command database. Run the checks separately with:

```sh
python3 tools/analyze.py
```

The script reads the saved target selection, analyzes only C++ sources in `src/system/`,
and fails on any diagnostic selected by `.clang-tidy` unless locally suppressed with
a reason. To analyze a different configured target, pass `--build-dir` with its build
directory. Mission payloads are outside this system-code profile.
