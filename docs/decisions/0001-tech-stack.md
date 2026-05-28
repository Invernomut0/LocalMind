# ADR-0001 — Technical Stack

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** founder

## Context

LocalMind is a macOS-native chat client for local LLMs with on-device RAG. We need to pick a stack that:

- Runs efficiently on Apple Silicon M1+ for 1B-14B class models.
- Supports embedded inference without external runtimes the user must install.
- Lets a solo developer ship a polished v1.0 in ~14 weeks.
- Stays compatible with GitHub-Releases distribution (Developer ID + notarization), not the Mac App Store.

## Decision

| Layer | Choice |
|-------|--------|
| UI | SwiftUI (macOS 15+, raised from 14 in [ADR-0004](./0004-raise-macos-minimum.md)) |
| Inference (primary) | `llama.cpp` via SwiftLlama bindings, GGUF format |
| Inference (Pro accelerated) | MLX-Swift as an optional backend on Apple Silicon |
| Embedding | `nomic-embed-text v2` (free), `mxbai-embed-large` (Pro), both via llama.cpp embedding mode |
| Vector DB | `sqlite-vec` (Alex Garcia) |
| Relational persistence | SQLite via `SQLite.swift` |
| File system access | NSOpenPanel + security-scoped bookmarks, FSEvents for incremental re-index |
| PDF parsing | `PDFKit` (built-in) |
| DOCX parsing | `pandoc` subprocess (optional, lazily invoked) |
| Auto-update | Sparkle 2 with EdDSA-signed appcast |
| Build / CI | GitHub Actions (build, lint, release with codesign + notarize) |
| Licensing | Lemon Squeezy (Merchant of Record) + Ed25519 offline cache |
| Crypto | `CryptoKit` (Apple), `swift-crypto` only if Linux CI parity is needed |

## Alternatives considered

- **MLX-only inference:** higher throughput on Apple Silicon but no GGUF compatibility, smaller community, model availability lags Hugging Face GGUF drops by hours/days. Rejected as primary; kept as optional accelerator.
- **Ollama as runtime, LocalMind as front-end only:** would force users to install Ollama separately and break the "single download, works offline" promise.
- **Electron / Tauri:** disqualified by the macOS-native UX thesis. Memory footprint, Spotlight integration, and Shortcuts intents all argue against it.
- **LanceDB / DuckDB VSS for vectors:** more powerful, but heavier binaries and more complex packaging. `sqlite-vec` ships as a single SQLite extension that Swift can link directly. Revisit at >5M embeddings (see ADR-0009 placeholder).

## Consequences

- We ship a single signed `.app` bundle with no runtime prerequisites — except a downloaded GGUF model on first run (or one bundled, see ADR-0006).
- We accept llama.cpp's slower-than-MLX baseline throughput on Apple Silicon, recovered for Pro users via the MLX backend.
- We are coupled to Apple platform APIs (CryptoKit, PDFKit, FSEvents, Shortcuts, NSOpenPanel, Keychain). Porting to Linux/Windows would be a separate project.
- Mac App Store is permanently off the table: embedded native binaries, recursive filesystem access, and subprocess invocations are incompatible with MAS sandboxing.
