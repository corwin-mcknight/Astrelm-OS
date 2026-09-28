# Fault Tolerance and Recovery

## Fault model

Astrelm targets machines that may operate unattended for long periods. In-scope faults include:

- software crashes,
- memory corruption and bad RAM,
- dead or unreliable CPU cores,
- failing storage,
- broken or degraded sensors,
- networking loss,
- bus failures,
- power degradation,
- thermal limits,
- radiation-induced bit errors, and
- correlated hardware failures.

A provisioned image defines which failures its hardware and mission are expected to tolerate. Astrelm provides the recovery machinery; the target hardware determines which physical failures can actually be survived.

## Detection and recovery

Detection is resource-specific.

A single missed sensor response can mark a sensor unhealthy immediately. A later good response can improve its health, but it does not by itself clear a quarantine that requires retesting.

Recovery can include:

- retrying or quarantining a resource,
- reducing its use,
- restarting a service,
- changing operating envelope,
- activating spare hardware,
- rebuilding state,
- waiting for conditions to improve, or
- rebooting as a last resort.

Recovery aggressiveness is mission-defined. A mission can limit how much energy is spent retrying, how long the system waits, and how much remaining redundancy may be consumed.

The Mission Manager decides mission-level recovery policy. It or an authenticated operator may authorize recovery actions that disregard declared hard requirements. The separate service supervisor watches services and enforces the Mission Manager's keep-alive decisions. If the manager is unavailable, the supervisor continues the last valid service policy while working to restart it; the supervisor does not choose a new mission policy. Individual services may request an override but cannot grant it themselves. An override cannot make unavailable hardware or capacity available; a component whose technical prerequisites are absent may stop or fail.

## Critical state

Astrelm should protect important system and mission state more aggressively than ordinary state.

Possible techniques include:

- redundant copies on independent hardware,
- historical copies,
- checks and cross-checks,
- excluding bad memory,
- selective replicated computation, and
- rebuilding state from surviving data.

Replication strength is provisioned policy.

For mission-owned data, mission software decides what conflicting copies mean. Astrelm provides health, provenance, replication, and recovery information.

Silent corruption is fundamentally best-effort. Hardware reports, health tests, redundant state, and independent computation can improve detection, but Astrelm cannot guarantee that every incorrect computation will be discovered.

If a CPU later becomes suspect, data it produced can also be marked suspect. Policy decides whether to keep it, discard it, or restart the affected service.

Historical state is retained as far as the mission and available resources justify.

## Power and danger states

The goal is the **best remaining chance of future mission success**, not continuous execution at any cost.

As power falls, Astrelm may shed work, preserve resumable state, and enter a low-power or non-operating state until enough energy returns.

Before an intentional communication outage, Astrelm should announce the planned transition if a channel is available. After waking, it should report the gap and relevant stored diagnostics when communication resumes.

For a solar-powered system, waiting may be better than repeatedly booting and draining the energy needed to recover.

## Resilience can degrade

A machine can still meet its mission while becoming more fragile.

Using a spare radio, backup sensor, or redundant copy may leave the system fully functional but less able to survive the next failure. Astrelm tracks that loss of resilience separately from current mission success.

## Reboot, boot recovery, and updates

Reboot is a last-resort recovery mechanism or a consequence of power loss. Permanent halt is not the intended response.

A reboot should try to restore the machine's last known logical operating state rather than start every mission from its initial profile. Services restart and rebuild their state from durable information; Astrelm does not restore process memory or execution contexts. Restoration is best-effort because failed resources or lost state may make an exact return impossible.

Services and mission packages should be restartable and updateable without rebooting the whole system where practical. System software may initially require rebooting.

The **bootloader is part of the recovery system**, not just a loader. It tracks **A/B system partitions**, accepts only signed boot payloads, and knows how to switch between slots under update or recovery policy. An operator cannot bypass signature verification during recovery. An update can therefore be staged separately from the currently running system, and recovery does not depend entirely on that running image remaining healthy enough to repair itself.

Quarantine survives reboot until a resource passes retesting. Current capability and trust are assessed again from new observations. Other mission-level recovery and diagnostic state may also need to survive reboot; the exact minimum persistent Mission Manager state is still undecided.

## Testing

Astrelm should be developed with aggressive fault injection.

Tests can:

- disconnect and restore sensors,
- remove RAM regions,
- halt CPUs,
- inject computational errors,
- remove storage,
- break buses,
- degrade networking,
- remove telemetry,
- lower available power, and
- impose thermal limits.

Tests do not need to physically destroy hardware. Emulation, controllable hardware interruption, and test-specific drivers can create the fault.

Silent loss, silent corruption, and silently violating declared mission requirements are failures. Pass/fail behavior is otherwise defined by the mission.

Fault injection should be able to inject faults without telling the running system which component is faulty when the purpose of the test is to exercise detection rather than only recovery.
