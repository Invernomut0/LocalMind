# LocalMind

> Local LLM chat with RAG. Native macOS. Offline by default.

LocalMind is a macOS-native chat client for local LLMs (via embedded `llama.cpp` and optional MLX) with on-device RAG over your own files. No cloud, no account, no telemetry.

**Status:** `v0.2.x-alpha` — working local chat shell with streaming `llama.cpp` inference, bundled model catalog, in-app downloader, a Sprint 3 remote-catalog fetch path with bundled fallback, RAM-aware model recommendations in the picker, and an upgraded embedded runtime that can load the newer `qwen3` GGUF family. Public roadmap in [`ROADMAP.md`](./ROADMAP.md).

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
swift build                        # debug build of all targets
swift test                         # full test suite (one E2E test is skipped without LOCALMIND_MODEL_PATH)
Scripts/build-app.sh debug         # assemble build/LocalMind.app (unsigned, ad-hoc codesigned for dev)
open build/LocalMind.app           # launch it
```

The plain SwiftPM executable lives at `.build/arm64-apple-macosx/debug/LocalMindApp` but macOS hides its window when run outside a bundle. Use `Scripts/build-app.sh` to assemble a real `.app` for local dev. The signed, notarized `.app` for distribution comes from the release pipeline in Sprint 7.

To run a real chat, either place a GGUF model in `~/Library/Application Support/LocalMind/Models/` (or set `LOCALMIND_MODEL_PATH=/path/to/model.gguf`) or let the first-run catalog download one for you. The app now prefers a remote catalog URL and falls back to the bundled catalog when offline or when the remote fetch fails. The bundled catalog currently includes curated picks such as Qwen 2.5 0.5B/3B/7B, Qwen 3 4B/8B, Phi 4 Mini, Gemma 3 4B/12B, Llama 3.2 3B, and Ministral 8B. The embedded runtime is now pinned to `llama.cpp` `b9374`, which is new enough to load the `qwen3` GGUF architecture that previously failed on `b5046`. When a local model matches a catalog entry, LocalMind now reuses the catalog's `promptTemplate` instead of relying only on filename heuristics.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) and [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md). Feature direction discussions happen in GitHub Discussions; architectural changes go through ADRs in `docs/decisions/`.

## License

[MIT](./LICENSE).
