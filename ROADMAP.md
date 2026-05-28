# LocalMind Roadmap

Public, community-facing roadmap. Updated weekly. The internal operating plan with hours and acceptance criteria lives separately.

## Status legend

- ☐ planned
- ◐ in progress
- ☑ shipped

## Pre-development — Sprint 0 (current)

- ◐ Apple Developer Program enrollment
- ◐ Repository scaffolding (this commit)
- ☐ Domain + landing page (Astro on GitHub Pages)
- ☐ ADR-0001 stack, 0002 license, 0003 distribution
- ☐ Social accounts + newsletter signup
- ☐ First "starting LocalMind" devlog

## v0.1.0-alpha — Sprints 1-2: Chat UI + base inference

- ☐ SwiftUI shell: conversation sidebar, chat area, input bar
- ☐ SwiftLlama integration, GGUF loading from bundle
- ☐ Token streaming with backpressure
- ☐ SQLite conversation persistence
- ☐ Qwen prompt template + configurable system prompt
- ☐ Token counter, stop generation, regenerate
- ☐ Unit tests for PromptBuilder + ChatEngine (≥70% Core coverage)

## v0.2.0-alpha — Sprints 3-4: Model catalog + downloader

- ☐ Static curated model catalog hosted on GitHub Pages
- ☐ Resumable URLSession downloader + SHA256 verification
- ☐ Storage management UI (list, size, delete)
- ☐ Multi-model switcher
- ☐ RAM detection + recommendation
- ☐ HF metadata integration

## v0.3.0-alpha — Sprints 5-6: RAG core

- ☐ NSOpenPanel + security-scoped bookmarks
- ☐ File walker for PDF / Markdown / code
- ☐ Token-aware chunker (~512 tok, 64 overlap)
- ☐ nomic-embed-text v2 via llama.cpp embedding mode
- ☐ sqlite-vec vector store
- ☐ Top-k retrieval + citation UI
- ☐ Free-tier one-folder limit enforced

## v0.4.0-beta — Sprint 7: Public beta distribution

- ☐ GitHub Actions release pipeline (codesign + notarize + staple)
- ☐ Sparkle 2 + EdDSA-signed appcast
- ☐ DMG distribution
- ☐ Onboarding flow (Welcome → model → folder)
- ☐ Privacy policy + Terms
- ☐ Show HN public launch (beta)

## v0.5.0-beta — Sprints 8-9: Polish + MLX backend

- ☐ Optional MLX-Swift backend (Apple Silicon throughput +30%)
- ☐ Error states across all flows
- ☐ Keyboard shortcuts + command palette
- ☐ Dark mode + VoiceOver pass
- ☐ Privacy-aware structured logging

## v0.6.0-beta — Sprints 10-11: Pro features (feature-flagged)

- ☐ Apple Notes integration (read-only SQLite)
- ☐ FSEvents incremental re-index
- ☐ mxbai-embed-large support
- ☐ Multi-folder management
- ☐ Shortcuts.app intents
- ☐ Menu bar quick access
- ☐ Cloud BYOK (Claude, OpenAI) via Keychain
- ☐ iCloud chat history sync (CloudKit)

## v0.9.0-rc — Sprints 12-13: Licensing

- ☐ Lemon Squeezy product + Ed25519 license keys
- ☐ Offline cache with 7-day grace
- ☐ Activation + deactivation (3-device cap)
- ☐ Entitlement gates uniform across Pro features
- ☐ Paywall UI

## v1.0.0 — Sprint 14: Coordinated launch

- ☐ Code freeze + bug-fix only
- ☐ ProductHunt + Show HN + /r/LocalLLaMA coordinated launch
- ☐ Press kit, demo video, screenshots
- ☐ Outreach to Mac press

## Post-launch backlog (no order)

- Hybrid retrieval (BM25 + semantic fusion)
- Agent tooling (local function calling)
- Team features (multi-seat licenses)
- Homebrew Cask
- Setapp evaluation
- Conference attendance (WWDC indie, Swift Heroes, NSSpain, Do iOS)
