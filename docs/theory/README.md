# Astrelm OS

These notes describe Astrelm's intended architecture. The repository [README](../../README.md) describes what is currently implemented.

- **Language:** C / C++
- **Previous OS:** [Archipelago](https://github.com/corwin-mcknight/Archipelago)
- **Architecture:** Non-UNIX microkernel with a Unix/POSIX-like userspace API. Shared core with ARM and RISC-V platform layers.

**Astrelm is an operating system for autonomous machines that must keep doing useful work as their hardware and environment degrade.**

Its goal is to preserve the **best remaining chance of future mission success**.

## What Astrelm is

Astrelm is not a general-purpose OS.

An image is built for a specific machine or class of machines, then flashed to the target. The image knows its hardware, drivers, mission software, expected resources, and recovery policy.

Targets include remote weather stations, drones, rovers, robots, boats, and spacecraft: systems that may run unattended for months or years and cannot assume a human can repair them.

## Core idea

**Degradation is normal operation.**

Astrelm treats the machine as a set of resources whose **advertised properties can change over time**. A resource is not merely working or failed: it may still provide useful service with less capacity, lower quality, worse timing, reduced confidence, or intermittent availability.

For example, a camera can advertise resolution, frame rate, latency, and reliability separately. A drop in frame rate is not the same failure as a drop in resolution even if both make the camera broadly "degraded." Missions can select on the exact properties they care about and choose different responses.

Astrelm exposes those changes to mission software so the machine can move into another useful operating mode instead of simply crashing or stopping.

Examples:

- less RAM → smaller buffers or fewer services,
- fewer CPUs → lower processing or sampling rates,
- lossy networking → reduced telemetry,
- failed storage → preserve the most important data elsewhere,
- low power → shed work and wait for better conditions.

If resources return, they can be tested and brought back into service.

A reboot does not clear a resource's quarantine. Quarantined resources remain ineligible for normal use until they pass retesting, while current capability and trust are assessed again from new observations.

## Missions

Astrelm can run several missions at once.

A mission defines what counts as useful operation. It can declare:

- hard and soft requirements,
- priorities,
- several operating modes,
- acceptable state loss,
- recovery policy, and
- what an operator may override.

Mission data is produced ahead of time by a **Mission Compiler**. It turns mission definitions, goals, resource dependencies, operating envelopes, priorities, and expected failure responses into the mission data shipped in the system image.

The compiler should precompute and check expected failure responses before deployment and identify declared or representable failure modes with no valid mission response. When an unanticipated combination occurs, the Mission Manager may construct a new operating plan from mission goals, priorities, and current capabilities. This does not make every physical failure predictable; it moves as much policy and consistency checking as possible out of the live failure path.

Applications can also publish requirements in executable metadata and change explicitly dynamic requirements at runtime.

If one mission fails, others may continue. If every mission fails, Astrelm still tries to preserve data, protect healthy resources, and recover to a state where some mission can run again.

The OS does not invent domain policy. If two temperature sensors disagree, the weather software decides what that means. Astrelm provides the health and dependency information.

## Resources, properties, and health

Anything that affects useful operation can be a resource: CPU, RAM, storage, sensors, buses, networking, power, thermal headroom, time, software services, or higher-level capabilities.

Each resource advertises the properties that describe what it can currently provide. Those properties are the primary interface to missions. **Healthy**, **degraded**, and **failed** are derived summaries of capability: a resource is degraded when one or more relevant properties leave their normal operating envelope while useful capability remains. Trust is assessed separately. A resource can be **unreliable** while also being healthy, degraded, or failed in capability terms. **Quarantine** is a separate state controlling eligibility for normal use; it does not erase measured capability or trust.

The **Mission Manager** decides mission-level policy and owns the mission-level resource graph and current resource state. The kernel does not maintain that model. Drivers, kernel mechanisms, and services expose observations and capabilities; the Mission Manager combines them with mission data and policy.

The **kernel** enforces mission policy for scheduling, resource allocation, and device use without becoming the authority on resource health. On boot, it enforces the posture marked as the default until the Mission Manager supplies another. If the Mission Manager becomes unavailable, the kernel continues enforcing its current posture.

A separate **service supervisor** watches services and coordinates their lifecycle. The mission profile specifies the bootstrap service set, while a reboot aims to restore the last known logical operating state rather than simply start over from that set. This means restarting services and rebuilding their state from durable information, not resuming a memory checkpoint. The supervisor enforces the Mission Manager's decisions about which services to keep alive; it does not make those decisions itself. If the Mission Manager is unavailable, the supervisor continues the last valid service policy and works to restart it without making new mission-level decisions.

Capability and trust assessments can carry confidence and reasons.

Health can propagate through dependencies. A service may report that it is degraded because it no longer has enough RAM, and its own degraded output may become a degraded resource consumed by another service.

Astrelm tracks both current capability and **remaining resilience**. A machine may still be meeting its mission after consuming its last spare radio or backup sensor, but it is now less able to survive another failure.

## Architecture

Astrelm uses a microkernel because restartable services and small fault-containment boundaries are central to the project.

Drivers, networking, telemetry, mission software, the Mission Manager, the service supervisor, and other replaceable services should normally live outside the kernel. Isolation exists mainly for **operational safety**, not for hostile local users.

A useful design analogy is: **what if the adaptive-partitioning idea of a fungible, changing resource were generalized from CPU allocation to the entire machine?** CPU, RAM, storage, sensors, bandwidth, power, thermal headroom, software services, and higher-level capabilities all become changing supplies that can be represented to missions.

The deeper goal is to push that representation below application-level orchestration. Astrelm should not treat the OS as a fixed substrate beneath an adaptive mission layer; as much of the machine as practical should participate in the same mission-visible resource model.

### Unix-like API, non-Unix system

Astrelm's internals are deliberately not UNIX-like, but its userspace API should be familiar enough that existing **POSIX applications and payloads can be ported with relatively little friction**.

POSIX compatibility is a portability surface, not an architectural constraint. Astrelm does not need to adopt UNIX's internal process model, "everything is a file," monolithic device semantics, or other assumptions simply because applications see familiar APIs for files, sockets, threads, time, memory, and process-like execution.

Where practical, compatibility APIs should map onto Astrelm's native abstractions rather than define them. Astrelm-native software can use richer mission, resource-health, and degradation interfaces that POSIX applications do not know about.

The goal is therefore: **existing payloads can feel Unix-like; the machine underneath does not have to be Unix.**

The execution model will use **jobs, tasks, and threads**. Their exact division is still being designed.

Scheduling is mission-aware. It considers priority, real-time needs, available compute, recovery work, and preservation work. The default is to favor long-term survivability, but mission policy or a remote operator can override that choice.

Astrelm is real-time capable. If compute capacity falls, software may intentionally reduce throughput to keep timing predictable.

## Failure and recovery

Astrelm is intended to handle software crashes, bad RAM, CPU failure or unreliability, storage loss, broken sensors, networking loss, bus failures, power degradation, thermal limits, radiation-induced errors, and correlated hardware faults.

It does not promise that every failure is survivable.

If unreplicated RAM disappears, the data in it is lost. Astrelm recovers around the loss rather than pretending the state can be reconstructed.

Recovery may mean restarting a service, quarantining hardware, reducing resource use, activating a spare, rebuilding state, waiting for better conditions, or rebooting as a last resort.

The bootloader participates in recovery. It tracks **A/B system partitions**, verifies signed payloads before boot, and can switch between slots under update or recovery policy. Signature verification remains mandatory during operator-directed recovery. This gives system-level recovery a layer below the running OS instead of requiring the currently booted image to repair itself successfully.

For power-related failures, intentionally waiting may be the best recovery. Continuous execution is less important than keeping the mission viable for the long term.

## Telemetry and control

Telemetry and remote control are the first major implementation focus.

Development starts with **serial**, then moves to networking.

Astrelm has two logical communication channels. The **telemetry channel** carries mission and system output from the machine, including health status, images, and readings. It is outbound only. The **control channel** carries traffic in both directions for interactive operator use, including inspection, changes, recovery, and updates. An operator can request data and receive it through the control channel. If configured for the mission, the control channel can also carry a limited selection or all telemetry output when the telemetry channel is unavailable.

The mission selects the communication hardware and transport for each channel. The channels may share a physical link, but either channel can degrade independently.

A useful rule for the system is:

> **Astrelm detects and propagates capability. Services describe what they can still do. Missions decide what is worth doing. Scheduling and resource allocation make that decision real.**

## Security

Astrelm is not a multi-user OS. It does not need UNIX users, PAM, or a local permission model.

Process isolation is mainly for fault containment.

Remote control is different: control traffic and updates must be authenticated and integrity-protected. An authenticated operator can direct mission policy and recovery, including overriding declared requirements, but cannot bypass signed boot payload verification.

## First physical target

A remote weather station is the first likely demonstration platform.

It gives Astrelm real sensors, telemetry, storage, power limits, and long-running data without starting with a safety-critical actuator.

The long-term demo is simple: repeatedly remove capability from a running station, watch its missions shrink without going silent, then restore resources and watch the system safely regain capability.

## Detailed design notes

[Mission and Resource Model](mission-and-resource-model.md)

[Fault Tolerance and Recovery](fault-tolerance-and-recovery.md)

[Telemetry, Control, and Operations](telemetry-control-and-operations.md)

[Open Design Questions](open-design-questions.md)
