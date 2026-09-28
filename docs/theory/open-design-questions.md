# Open Design Questions

These are the remaining unresolved questions. Answered questions have been folded back into the main design notes.

## Mission representation

1. **What exact source language or schema feeds the Mission Compiler and represents mission states, priorities, dependencies, resource-property constraints, and operating envelopes?**
2. **How does Astrelm verify that a component actually completed a requested transition into a new operating envelope?**
3. **Which job/task/thread object owns requirements, and how are requirements inherited or aggregated across cooperating components?**
4. **How are stable capability identifiers created and versioned across software updates?**

## Persistent recovery state

1. **What exact Mission Manager state should survive reboot so that Astrelm remembers quarantined hardware, previous failures, and important diagnostic history?**

Quarantine is known to persist across reboot until retesting; current capability and trust are assessed again. Boot-image recovery state is separate: the bootloader owns A/B slot tracking, signed-payload verification, and slot switching. The unresolved question is what other mission/resource state must persist across boots.
