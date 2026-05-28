# Changelog

All notable changes to LocalMind are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Version numbers follow [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Initial repository scaffolding: Swift Package layout, GitHub Actions workflows (build / lint / release), CONTRIBUTING, CODE_OF_CONDUCT, MIT LICENSE, ROADMAP, first three ADRs.
- Placeholder source files for `LocalMindApp`, `LocalMindCore`, `LocalMindRAG`, `LocalMindLicense`, `LocalMindStorage`.
- Build scripts placeholders: `Scripts/notarize.sh`, `Scripts/build-llama.sh`, `Scripts/make-appcast.sh`.
- `LlamaInferenceBackend` (Sprint 1): real `llama.cpp` inference via [SwiftLlama 0.4.0](https://github.com/ShenghaiWang/SwiftLlama), streaming tokens through `AsyncThrowingStream`.
- `InferenceRequest` refactored to chat-shaped fields (`systemPrompt`, `userMessage`, `history`, `template`); `PromptBuilder` now maps `[ChatMessage]` → `InferenceRequest`. SwiftLlama owns per-model prompt templating.
- `LiveChatEngine` glues `PromptBuilder` + `InferenceBackend` and infers the prompt template from the model filename.
- `ModelResolver` locates the GGUF model via `LOCALMIND_MODEL_PATH` env var, falling back to `~/Library/Application Support/LocalMind/Models/`.
- `ChatStore` (LocalMindStorage): JSON-file conversation persistence in `~/Library/Application Support/LocalMind/conversation.json`. Will move to SQLite when `sqlite-vec` lands in Sprint 5.
- SwiftUI shell: `ContentView` routes `loading` / `ready` / `modelMissing` / `failed` phases. `ChatView` streams the assistant reply, supports Cmd+Return to send, Cmd+. to stop, and persists on every chunk.
- `Scripts/build-app.sh`: assembles `build/LocalMind.app` with embedded `llama.framework`, ad-hoc codesign, and a proper `Info.plist` so the window actually appears outside Xcode. Replaced in Sprint 7 by the codesigned + notarized release pipeline.
- `LocalMindApp.init` sets `NSApplication.shared.setActivationPolicy(.regular)` and the window's `.onAppear` activates the app, so launching from `swift run` or the dev `.app` foregrounds the window reliably.
- ADR-0004: raise minimum macOS to 15 (Sequoia) to consume SwiftLlama 0.4.0.
- ADR-0005: vendor SwiftLlama 0.4.0 sources under `Sources/Vendor/SwiftLlama/`. Patches the llama.cpp b5046 vocab-API mismatch (model pointer → vocab pointer in `llama_tokenize` / `llama_token_to_piece` / `llama_vocab_is_eog`), tokenizes the prompt with `parse_special=true` so ChatML markers are recognized as special tokens, and rewrites the ChatML encoder to a clean Qwen-compatible template that includes the system prompt. Without these three fixes the app crashed at SIGBUS on the first message, or produced character-by-character corrupted output that never terminated.

### Changed
- Minimum macOS bumped from 14 (Sonoma) to 15 (Sequoia). See ADR-0004.
- `swift-tools-version` bumped from 5.9 to 6.0; CI runs on `macos-15` / Xcode 16.

## [0.2.0-alpha] — 2026-05-28

### Added
- Model catalog + in-app downloader (Sprint 2). First-run flow no longer requires the user to drop a `.gguf` by hand: the app shows a curated catalog, downloads the chosen model from Hugging Face with progress UI, verifies SHA-256 streaming, then loads it.
- `ModelCatalogEntry` schema (Codable, Sendable) with family, parameter count, quantization, downloadURL, sha256, sizeBytes, ramMinGB, promptTemplate, contextLength.
- `BundledModelCatalog` loads `Resources/Models/catalog.json` via `Bundle.module`, with a fallback path for `.app`-bundled builds where SPM resource bundles live under `Contents/Resources/`.
- `ChecksumVerifier`: streaming SHA-256 over a `Foundation.InputStream` using CryptoKit.
- `ModelDownloader`: `URLSessionDownloadTask` driven by a delegate, callback-based progress, atomic move from the system temp location, checksum gate, and idempotent re-download when an existing file fails verification.
- `AppLauncher` gains `catalogPicker` and `downloading` phases; `ContentView` routes them to `ModelPickerView` and `DownloadingView`.
- `Scripts/build-app.sh` now copies SwiftPM resource bundles into `Contents/Resources/`.
- Tests: `ModelCatalogTests` (schema decode + future-version gate), `ChecksumVerifierTests` (known fixture, mismatch, unreadable file, large file), `ModelDownloaderTests` (mock `URLProtocol` for download success, SHA mismatch cleanup, existing-file skip).
- ADR-0006 documents the catalog format.

[Unreleased]: https://github.com/Invernomut0/LocalMind/compare/v0.2.0-alpha...HEAD
[0.2.0-alpha]: https://github.com/Invernomut0/LocalMind/compare/v0.1.0-alpha...v0.2.0-alpha
