# ADR-0004 — Raise minimum macOS to 15 (Sequoia)

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** founder
- **Supersedes (in part):** [ADR-0001](./0001-tech-stack.md) (the "SwiftUI macOS 14+" row)

## Context

Sprint 1 integrates [SwiftLlama](https://github.com/ShenghaiWang/SwiftLlama) as the primary `llama.cpp` binding for the inference layer. SwiftLlama `0.4.0` declares `.macOS(.v15)` in its `Package.swift` and pulls in a `llama.cpp` xcframework that requires the same minimum. There is no published SwiftLlama release that supports both an up-to-date `llama.cpp` and macOS 14.

Options considered:

1. **Pin SwiftLlama 0.2.0** — only release that still supports macOS 12+. Bundles an old `llama.cpp` revision missing GGUF v3 features, Qwen 2.5 chat template fixes, and recent Metal kernels. Rejected as a long-term tax.
2. **Vendor `llama.cpp` directly via `Scripts/build-llama.sh`** — gives us full control and macOS 14 compatibility, at the cost of taking on the entire xcframework build/codesign chain ourselves. Rejected for Sprint 1 — moves what should be a one-week task into a multi-week one and defers user-visible progress.
3. **Raise the platform minimum to macOS 15.** Accepted.

## Decision

The minimum supported macOS for LocalMind is **macOS 15 (Sequoia)**.

Concretely:

- `Package.swift` pins `.macOS(.v15)` and `swift-tools-version: 6.0`.
- README, CONTRIBUTING, and benchmarks reflect macOS 15 / Xcode 16 / Swift 6+.
- CI runs on `macos-15` with `Xcode_16.app`.
- ADR-0001's "SwiftUI macOS 14+" row is annotated as superseded by this ADR.

## Consequences

**Accepted trade-offs:**

- Users still on macOS 14 cannot install LocalMind. Sonoma's installed base at launch (target W14, June 2026) is expected to be a minority of Apple-Silicon Macs; Sequoia adoption has been the fastest macOS uptake in recent cycles.
- We tie ourselves to the cadence of upstream SwiftLlama. If SwiftLlama stops being maintained we fall back to option 2 (vendor `llama.cpp` ourselves) — option preserved, not exercised.

**Gains:**

- Sprint 1 ships a working end-to-end inference path without us owning the xcframework build pipeline.
- SwiftLlama already exposes `AsyncThrowingStream<String, Error>` from `start(for:)`, which matches our `InferenceBackend.generate(_:)` shape directly — no adapter layer beyond `Prompt` translation.
- Free access to upstream `llama.cpp` improvements (Metal kernels, GGUF format updates, model template fixes) without us cutting xcframework releases by hand.

**Reversibility:**

- The decision is reversible: rip out SwiftLlama, restore macOS 14 in `Package.swift`, build `llama.cpp` ourselves. The cost is one to two sprints of plumbing work, not a fundamental redesign.

## References

- SwiftLlama Package.swift at `v0.4.0` → `.macOS(.v15)`.
- Upstream `llama.cpp` xcframework consumed via SwiftLlama → release `b5046`.
