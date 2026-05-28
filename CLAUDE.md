# Claude Code — Project Brief for LocalMind

This file is auto-loaded by Claude Code when this repository is opened. It exists to give any AI assistant working on LocalMind enough context to be useful immediately, without re-deriving the architecture or repeating decisions already made.

## What LocalMind is

A macOS-native chat client for local LLMs (`llama.cpp` embedded, MLX optional) with on-device RAG over user files. Privacy-first, offline by default. Distributed via GitHub Releases (signed + notarized) — never the Mac App Store.

Current public surface: [README](./README.md) · [ROADMAP](./ROADMAP.md) · [Architecture](./docs/architecture.md) · [ADRs](./docs/decisions/).

## Strategic decisions (already made — do not re-litigate)

- **Open-core**: client is MIT-licensed; Pro features gated by an Ed25519-validated €49 one-time license sold via Lemon Squeezy. See [ADR-0002](./docs/decisions/0002-license-model.md).
- **Tech stack**: SwiftUI + SwiftLlama (llama.cpp) + MLX-Swift (optional Pro) + sqlite-vec + Sparkle 2 + GitHub Actions. See [ADR-0001](./docs/decisions/0001-tech-stack.md).
- **Distribution**: GitHub Releases only; Apple Developer ID + notarization mandatory. No Mac App Store path. See [ADR-0003](./docs/decisions/0003-distribution-channel.md).
- **Hardware**: Apple Silicon only (M1+). Intel explicitly unsupported.
- **macOS minimum**: 15 (Sequoia). See [ADR-0004](./docs/decisions/0004-raise-macos-minimum.md).
- **Build-in-public**: repo public from day 1, weekly devlogs, GitHub Discussions used for non-trivial design questions.

## Language and style

- All code, comments, ADRs, commit messages, docs, and user-facing copy are in **English**.
- Italian is acceptable only in conversation with the founder; never in files.
- Default to **no comments** in code. Only add a comment when the *why* is non-obvious.
- Don't add docs files unless asked.

## Repository layout

```
Sources/LocalMindApp/        SwiftUI shell, app lifecycle, menu bar, paywall UI
Sources/LocalMindCore/       Inference abstraction, model mgmt, prompt building
Sources/LocalMindRAG/        Indexing, embedding, retrieval
Sources/LocalMindLicense/    Ed25519 offline validation + Lemon Squeezy sync
Sources/LocalMindStorage/    SQLite + sqlite-vec + Keychain + bookmarks
Tests/                       Mirrors Sources/ layout
Scripts/                     notarize.sh, build-llama.sh, make-appcast.sh
docs/decisions/              Architecture Decision Records (numbered)
.github/workflows/           build.yml, lint.yml, release.yml
```

## How to build and test

```bash
swift build           # debug build of all targets
swift test --parallel # run all unit tests
swift test --filter PromptBuilderTests   # focused
```

CI runs the same on macOS 15 via `.github/workflows/build.yml`. The release pipeline (`release.yml`) takes care of codesign + notarize + appcast and triggers on tags `v*`.

## Conventions

- **Branching**: `main` is protected. Feature branches: `feat/<slug>`. Releases tagged `vMAJOR.MINOR.PATCH[-prerelease]`.
- **Commits**: imperative mood, English. Conventional-style prefixes are encouraged (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`).
- **ADRs**: architectural changes get a new file under `docs/decisions/NNNN-slug.md`. Don't change architecture without one.
- **Tests**: non-trivial code ships with tests. Coverage gates: ≥60% on `Core`, `RAG`, `License`.
- **External deps**: pinned in `Package.swift`. We add them in the sprint that needs them, not earlier — keeps Sprint 0 hermetic.

## Useful pointers

- Internal operating plan (private, ~/.claude/plans/): `~/.claude/plans/sviluppiamo-l-idea-di-tingly-falcon.md`. Contains full sprint-by-sprint roadmap, risk register, kill/scale criteria, marketing plan. Read this for context on *why* the current sprint exists.
- Public roadmap: [ROADMAP.md](./ROADMAP.md).
- GitHub repo: https://github.com/Invernomut0/LocalMind.

## Working with the founder

- Single solo developer, full-time ~40h/week.
- Aggressive build-in-public: weekly devlogs on X/Bluesky/Mastodon, dev.to long-form, GitHub Discussions for design.
- Marketing budget: €0. Tactics are documented in the private operating plan, not in this repo.
- Founder identity in commits: `Invernomut0 <Invernomut0@users.noreply.github.com>` (configured per-repo).
