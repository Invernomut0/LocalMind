# LocalMind

> Local LLM chat with RAG. Native macOS. Offline by default.

LocalMind is a macOS-native chat client for local LLMs (via embedded `llama.cpp` and optional MLX) with on-device RAG over your own files. No cloud, no account, no telemetry.

**Status:** Sprint 0 — pre-development scaffolding. Not yet usable. Public roadmap in [`ROADMAP.md`](./ROADMAP.md).

## Why LocalMind

- **Privacy-first**: indexing and inference happen entirely on your Mac. No file ever leaves your device unless you explicitly enable a cloud BYOK fallback.
- **macOS-native**: SwiftUI, menu bar, Spotlight extension, Shortcuts intents, Apple Notes integration. Built for the platform, not ported to it.
- **Chat-first RAG**: one focused thing done well. Not an "everything app".
- **Open-core**: the client is MIT. Pro features (Apple Notes, multi-folder, mxbai-embed-large, iCloud sync, Shortcuts) are unlocked by a one-time €49 license.

## Distribution

LocalMind is distributed via GitHub Releases — signed with an Apple Developer ID and notarized. Updates land through Sparkle 2. **Not** on the Mac App Store (filesystem access and embedded native binaries are incompatible with MAS sandboxing).

## Hardware support

- Apple Silicon only (M1 and newer). Intel Macs are unsupported by design.
- 16 GB RAM recommended for 7B-class models; 8 GB works for sub-3B models.
- macOS 15 (Sequoia) or newer.

## Architecture (high level)

```
LocalMindApp ── LocalMindCore (inference, model mgmt)
            ├── LocalMindRAG  (indexing, embedding, retrieval)
            ├── LocalMindLicense (Ed25519 offline + Lemon Squeezy sync)
            └── LocalMindStorage (SQLite + sqlite-vec + Keychain + bookmarks)
```

See [`docs/architecture.md`](./docs/architecture.md) and the ADRs under [`docs/decisions/`](./docs/decisions/).

## Build (developer)

Requires Xcode 16 / Swift 6+ and macOS 15+.

```bash
swift build
swift test
```

The skeleton compiles without external dependencies; SwiftLlama / mlx-swift / Sparkle / sqlite-vec are added per the sprint plan in [`ROADMAP.md`](./ROADMAP.md).

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) and [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md). Feature direction discussions happen in GitHub Discussions; architectural changes go through ADRs in `docs/decisions/`.

## License

[MIT](./LICENSE).
