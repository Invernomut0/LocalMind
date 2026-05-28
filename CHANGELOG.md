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

### Changed
- Minimum macOS bumped from 14 (Sonoma) to 15 (Sequoia). See ADR-0004.
- `swift-tools-version` bumped from 5.9 to 6.0; CI runs on `macos-15` / Xcode 16.

[Unreleased]: https://github.com/Invernomut0/LocalMind/compare/HEAD...HEAD
