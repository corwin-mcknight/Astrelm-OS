# Astrelm C++ code style

This is the coding standard for Astrelm-owned **kernel, driver, and system-provided
service** code. Mission payloads may set their own rules. The standard is informed
by MISRA C++:2023 and the C++ Core Guidelines; Astrelm does not claim MISRA compliance.

## Language and clarity

Use C++17. Use a language feature when it makes the job simpler, safer, or clearer;
there is no requirement to write C-like C++. Prefer straightforward control flow,
small functions, and types that express their invariants. Avoid abstractions that do
not remove a real source of error or duplication. System code does not use exceptions
or RTTI.

Use four spaces for indentation and keep lines within 100 columns where practical.
Use `snake_case` for functions, variables, and namespaces; `PascalCase` for types.
Use braces for control-flow bodies, including a single statement, and put function
opening braces on the next line. Comments should explain constraints and reasons
that the code itself cannot make clear.

## Ownership, lifetimes, and bounds

Make **ownership explicit** in types and interfaces. A raw pointer or reference is
non-owning. State the lifetime of borrowed data in the API contract, and carry a
length with a borrowed buffer. Use a distinct owning type or handle when an API
transfers ownership. Review every indexing operation against the actual buffer bound;
do not assume that pointer arithmetic or a cast makes an access safe.

Initialize objects before use. Avoid undefined behavior, narrowing conversions,
implicit signedness changes, and hidden lifetime dependencies. Prefer fixed storage.
If runtime allocation is needed, use the component's controlled arena or SLAB
facility and handle exhaustion explicitly.

## Failure handling

Treat resource restriction and ordinary operation failures as expected outcomes.
Fallible system APIs shall use a project `Result<T, E>` type with an explicit error
value, and callers shall handle the result. Mark result values `[[nodiscard]]` so an
ignored failure is visible at compile time. A broken internal invariant is a defect:
make it detectable and do not silently continue as if the operation succeeded.
Assertions are for invariants, not for expected resource failures.

## Hardware boundaries

Confine register access, integer-to-pointer conversions, `volatile`, and other
hardware-specific operations to small architecture or board interfaces. Code above
those interfaces should use typed operations. Use named C++ casts when conversion is
necessary; document any conversion whose correctness depends on a hardware address,
ABI, or layout. An exemption must identify the exact operation and reason. A tool
suppression does not make an unsafe operation safe.

## Checks and exemptions

Build warnings are errors. The normal build runs `python3 tools/analyze.py` after
configuration; it can also be run directly as described in [BUILDING.md](BUILDING.md).
The checked-in `.clang-tidy` selects Clang Static Analyzer, bug-prone, and focused
C++ checks. Every diagnostic from that configured set fails the analysis command.
We select checks that apply to freestanding code; enabling every check would make
ordinary bounded arrays and MMIO code appear to require exemptions everywhere.

Fix findings or use the tool's **local suppression syntax** at the smallest useful
scope. Put a nearby comment explaining why the exception is required and why it is
bounded or safe in its context. Include the exact check ID in the suppression. A
whole-file suppression requires a reason that applies to the whole file. Do not
disable checks globally to hide a finding in one location.

The analyzer gate supplements review. Reviewers must still check ownership,
lifetime, bounds, failure propagation, and hardware assumptions that the configured
tools cannot prove. Changes to `.clang-tidy` are changes to this standard and should
be reviewed as such.
