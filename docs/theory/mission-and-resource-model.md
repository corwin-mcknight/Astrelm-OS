# Mission and Resource Model

## Mission model

Astrelm can run multiple missions. A mission says what useful operation means for the machine.

Missions can define:

- **hard requirements** for normal operation,
- **soft requirements** that may be reduced,
- priorities,
- several operating envelopes,
- acceptable state loss,
- recovery policy, and
- remote overrides.

If one mission fails, others may continue. If all missions fail, Astrelm still tries to preserve data, protect healthy resources, and return to a state where some mission can run.

## Mission Compiler and configuration

Each image contains mission data generated ahead of time by the **Mission Compiler**. The compiler consumes the mission definition and produces the representation used by the Mission Manager at runtime.

The source definition describes missions, goals, priorities, resource dependencies, resource-property constraints, operating envelopes, allowed transitions, expected failure responses, and the mission profile's bootstrap service set. The compiler should precompute and check expected failure responses and identify declared or representable failure modes for which no valid mission path exists.

The Mission Manager can select a precomputed response when one applies. For an unanticipated combination of failures, it may construct a new operating plan from mission goals, priorities, and current capabilities rather than requiring a precompiled path. Recovery may also act outside declared requirements when needed, under the override authority described below.

Applications can also publish requirements of their own. Some metadata is static and inspectable from the executable image:

- resources the component exports,
- resources it consumes,
- static hard requirements, and
- static soft requirements.

A running component can add or change explicitly dynamic requirements through system calls.

A remote operator can override soft requirements and pin dynamic policy. A hard requirement compiled into a binary remains part of that binary's declared requirements; changing the declaration requires updating the binary. During recovery, the Mission Manager or an authenticated operator may authorize ignoring a hard requirement. Individual services may request an override but cannot authorize one for themselves. Ignoring a requirement does not supply a missing technical prerequisite: a service that needs 32 MiB of RAM may terminate if less memory is available.

## Resources and advertised properties

Anything that affects useful operation can be a resource: CPU, RAM, storage, sensors, buses, networking, power, thermal headroom, time, software services, and higher-level capabilities.

Capabilities can be exposed as named resources so that applications depend on what the system can do, not only on a particular device.

Each resource advertises the properties that describe its current capability. Examples include available bytes, bandwidth, latency, frame rate, resolution, thermal margin, or whatever dimensions are meaningful for that resource. Trust and confidence in the advertised capability are assessed separately.

Missions select on those properties directly. A camera whose frame rate falls outside normal limits can trigger a different mission transition from a camera whose resolution falls, even though both could be summarized as "degraded."

## Resource state ownership

The **Mission Manager** decides mission-level policy and owns the mission-level resource graph, advertised property values, dependency relationships, and derived health state. The kernel does not keep this state. The **kernel** enforces Mission Manager policy for scheduling, resource allocation, and device use. On boot, it enforces the posture marked as the default until the Mission Manager supplies another. If the Mission Manager becomes unavailable, the kernel continues enforcing its current posture. A separate **service supervisor** watches services and coordinates their lifecycle. It enforces the Mission Manager's decisions about which services to keep alive rather than deciding that policy itself.

Drivers, kernel subsystems, and services publish observations or capabilities. The Mission Manager interprets those observations using compiled mission data and current policy. The kernel applies Mission Manager decisions through its enforcement mechanisms without owning the mission-level resource graph.

The mission profile specifies the bootstrap service set. A reboot should try to restore the last known logical operating state rather than always replay that initial set. Services restart and rebuild their state from durable information; process memory and execution contexts are not checkpointed. If the Mission Manager becomes unavailable, the service supervisor continues the last valid service policy and works to restart the manager without making new mission-level decisions. The supervisor's own bootstrap path cannot depend on the Mission Manager.

A coarse capability label remains useful for diagnostics and generic policy:

- **healthy** — relevant properties are within their normal operating envelope,
- **degraded** — one or more relevant properties are outside normal limits but useful capability remains,
- **failed** — the resource cannot provide mission-usable capability.

**Unreliable** is a separate trust assessment for behavior or evidence that makes the resource unsafe to treat as predictably available. It can coexist with any capability label. Capability and trust assessments can carry confidence, reasons, and dependencies. A lower-level property change can cause a service to change the properties it advertises, which can in turn affect another component.

**Quarantine** is a separate use-control state. A resource may measure healthy capability while remaining quarantined and ineligible for normal use. Quarantine does not replace its capability or trust assessment.

Hardware topology only needs to be modeled as deeply as the mission requires, but independence claims must be backed by real topology. Four copies on one RAM device are not four independent copies.

Resource state is reversible. Quarantine survives reboot and remains in effect until the resource passes retesting; a reboot does not turn a suspect resource into a trusted one. Current capability and trust are assessed again from new observations. Confidence, history, retry limits, cooldowns, and hysteresis can be used to avoid oscillation; exact policy is mission-defined.

## State and operating envelopes

Operating envelopes can be defined directly over resource properties. For example, a camera mission may prefer 30 Hz at full resolution, accept a lower frame rate while keeping resolution, accept a lower resolution for another mode, and stop only when the remaining combination is no longer useful. Memory-backed behavior such as buffer duration can be expressed the same way.

Components can also declare acceptable state loss. State can be classified by mission policy as disposable, reconstructable, durable, replicated, or critical.

If RAM disappears and unreplicated state was stored there, that state is lost. Astrelm does not pretend otherwise. It recovers system health, records the loss, and continues from trustworthy state.

## Scheduling

Scheduling considers:

- mission priority,
- real-time needs,
- current trustworthy compute capacity,
- recovery work,
- preservation work, and
- work that improves future survivability.

Survivability is the default preference when current output conflicts with future mission success, but mission policy or a remote operator can override it.

Soft requirements may be violated during transitions. Authorized recovery actions may also operate outside declared hard requirements when necessary, without guaranteeing that affected components can continue running.

If resource transitions cannot all make progress, lower-priority work degrades first. If equal-priority work is genuinely deadlocked, one side may be degraded to restore progress.

The scheduler does not need to solve every possible policy interaction. Its job is to keep the machine moving toward a viable operating state.

## Real-time behavior

Astrelm is real-time capable.

When resources shrink, a mission may trade throughput for predictability. Losing a CPU might reduce a sampling loop from a high frequency to a lower rate that can still meet its timing guarantees.

Those changes must be visible to mission software. Silent deadline loss is a failure.
