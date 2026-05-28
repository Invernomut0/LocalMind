# LocalMind Architecture

This document is a high-level orientation for contributors. Detailed decisions are recorded as ADRs in [`decisions/`](./decisions/). Implementation lives under `Sources/`.

## Goals

- Run inference and indexing entirely on-device.
- Stay macOS-native end-to-end: SwiftUI, system frameworks, minimal third-party UI.
- Keep modules small enough to reason about independently and test in isolation.
- Avoid leaking persistence concerns into UI or domain code.

## Module map

```
                        ┌────────────────────────┐
                        │      LocalMindApp      │
                        │  SwiftUI views, menu   │
                        │  bar, Shortcuts intents│
                        └───────────┬────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            ▼                       ▼                       ▼
┌───────────────────┐  ┌──────────────────────┐  ┌─────────────────────┐
│   LocalMindCore   │  │     LocalMindRAG     │  │  LocalMindLicense   │
│  ChatEngine       │  │  Indexer             │  │  LicenseStore       │
│  ModelManager     │  │  Embedder            │  │  LicenseValidator   │
│  InferenceBackend │  │  VectorStore         │  │  EntitlementGate    │
│  PromptBuilder    │  │  Retriever           │  │                     │
└─────────┬─────────┘  └──────────┬───────────┘  └──────────┬──────────┘
          │                       │                         │
          └───────────────────────▼─────────────────────────┘
                          ┌───────────────────┐
                          │ LocalMindStorage  │
                          │  SQLite + sqlite- │
                          │  vec, Keychain,   │
                          │  bookmarks        │
                          └───────────────────┘
```

## Module responsibilities

| Module | Purpose |
|--------|---------|
| `LocalMindApp` | SwiftUI views, app lifecycle, menu bar, Shortcuts intents, paywall UI |
| `LocalMindCore` | Inference abstraction (llama.cpp + MLX), model lifecycle, prompt assembly, token streaming |
| `LocalMindRAG` | File indexing pipeline, chunking, embedding, retrieval, citation tracking |
| `LocalMindLicense` | Offline license validation (Ed25519), Lemon Squeezy sync, entitlement gates for Pro |
| `LocalMindStorage` | SQLite persistence (chat history, vector index via sqlite-vec), Keychain, security-scoped bookmarks |

## Cross-module rules

- `LocalMindApp` depends on every other module; nothing depends on it.
- `LocalMindRAG` reuses the inference engine from `LocalMindCore` for embeddings — there is no second model runtime.
- All persistence flows through `LocalMindStorage`. Other modules never touch disk directly.
- `LocalMindLicense` exposes a single `EntitlementGate` interface; feature code never inspects raw license data.

## Threading

- UI: main actor.
- Inference, indexing, embedding: dedicated background tasks. Each runs on a serial executor so multiple Pro features cannot starve each other.
- Streaming token delivery uses an `AsyncStream` that bridges the inference task to the SwiftUI view.

## Concurrency boundaries

Swift Concurrency (`async/await`, actors) is the default. We avoid `DispatchQueue` except where required by Apple SDKs (e.g. `FSEventStreamCreate` callbacks). Long-running pipelines (indexing) cooperate with `Task.checkCancellation()` so the user can cancel cleanly.

## Failure model

- Recoverable errors surface to the user with a clear next action (retry, change model, free disk).
- Unrecoverable errors (corrupt index, mismatched SHA256) refuse to proceed and log to the local diagnostics file.
- We do not silently fall back from local to cloud — that would defeat the privacy promise.
