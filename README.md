# Astrelm OS

**Astrelm is an operating system for autonomous machines that must keep doing useful work as their hardware and environment degrade.** Its goal is to preserve the best remaining chance of future mission success.

It is intended for unattended systems such as remote stations, drones, rovers, and spacecraft. Astrelm treats reduced capacity, quality, timing, or reliability as useful information rather than treating every resource as simply working or failed.

## Current state

The first target is **riscv64 / virt / minimal**. Its kernel boots directly in QEMU through OpenSBI and reports its startup on the serial console. The build also creates three standalone ext2 partition images, but they do not boot yet, and the minimal payload does not run.

Build requirements and commands are in [BUILDING.md](BUILDING.md).

## Source organization

Implementation lives under `src/`. Target configuration is in `src/config/`, kernel code in `src/system/kernel/`, and each mission package owns its applications and configuration in `src/payloads/<mission>/`.
