# Telemetry, Control, and Operations

## First implementation focus

Telemetry and remote control are the first major end-to-end subsystem.

The initial implementation path is **serial**, followed by networking. A deployed mission selects the communication hardware and transport for each channel; possible links include the Deep Space Network or Meshtastic.

This provides an early vertical slice through boot, drivers, IPC, service lifecycle, structured resource/property reporting, derived health reporting, control commands, restart behavior, and eventually degraded communications.

## Telemetry and control channels

The **telemetry channel** is outbound only. It carries any mission or system output intended for a remote recipient, including health status, images, sensor readings, and other mission data.

The **control channel** carries traffic in both directions. It is the interactive path for operator commands and replies, and provides a backup way to request and retrieve data from the machine. Mission configuration can also permit limited or full telemetry failover onto this channel when the telemetry channel is unavailable. Limited failover sends the configured subset of output; full failover sends telemetry output through the control channel, subject to its available capacity.

The channels may use different hardware or share the same physical link, but Astrelm treats them as separate capabilities. Under bandwidth pressure, output not carried by the available channels may be reduced or stored according to mission policy.

Mission software and system services send their output to the telemetry channel. Sensor readings may first enter the machine through drivers and be used by a mission; when sent to a remote recipient, they become telemetry output. The control channel can return requested data directly to an operator and carry configured telemetry output during failover.

Each producer and communication layer reports what it knows about its own capability. The layer with enough mission context chooses the response to a failure.

> **Astrelm detects and propagates capability. Services describe what they can still do. Missions decide what is worth doing. Scheduling and resource allocation make that decision real.**

## Remote operators

Astrelm is autonomous by default, but an authenticated remote technician may direct mission policy and recovery when communications are available.

An operator may:

- change mission policy and priorities,
- inspect diagnostics,
- force use of suspect hardware,
- restart components,
- update mission software,
- pin resource limits,
- disable components, and
- override automated recovery choices.

An override changes policy, not observed reality. Forcing use of a suspect CPU does not erase its unhealthy state.

An authenticated operator may authorize ignoring a hard requirement during recovery. A service may request an override but cannot authorize one for itself.

## Security model

Astrelm is not a multi-user OS.

It does not need UNIX users, PAM, or local account policy. Internal process isolation exists mainly for fault containment and operational safety.

The remote boundary is different. Control and software updates must be authenticated and integrity-protected.

Once an operator is authenticated and authorized, that operator may direct mission policy and recovery, including overriding declared requirements. The bootloader still requires signed boot payloads.

## Observability

Astrelm acts like a black box.

It should retain enough history to explain:

- health changes,
- failures,
- recovery attempts,
- operating-envelope changes,
- mission changes,
- lost resilience,
- restarts, and
- remote overrides.

Diagnostic retention is mission-defined because it competes with mission data, bandwidth, storage, and energy.

Unexpected silence while communication is expected is a failure. A planned low-power state may intentionally stop communication; Astrelm should announce that transition when a channel is available and report the resulting gap after waking. Other degradation should be visible whenever communication permits.

## Initial weather-station target

A remote weather station is a strong first physical target because it combines sensors, telemetry, storage, power limits, and long-running data collection without requiring a safety-critical actuator.

Example degradation:

- telemetry loss → store observations locally,
- sensor loss → continue with reduced weather data,
- RAM loss → shrink buffers or stop low-priority services,
- CPU loss → reduce processing or sample rate,
- storage loss → change retention strategy,
- low power → shed work and preserve resumable state.

The long-term demo is to repeatedly remove capability, watch missions shrink, then restore resources and watch the system safely regain capability.
