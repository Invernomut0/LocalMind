# ADR-0002 — Open-Core License Model

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** founder

## Context

LocalMind targets the r/LocalLLaMA / indie-Mac / privacy-first audience. This community is sensitive to two things:

1. Closed-source paywalled software that withholds source for no clear reason.
2. Subscription pricing for tools they expect to own forever.

At the same time, a solo developer needs a sustainable revenue model to justify full-time work on the project.

## Decision

LocalMind ships as **open-core**:

- The entire SwiftUI client lives in this repository under the **MIT license**, including the source code of Pro features. Anyone can read, fork, study, and contribute.
- A subset of features is gated by an **entitlement check** keyed off a one-time **€49 license** purchased through Lemon Squeezy. License validation is Ed25519-signed and works offline with a 7-day grace period.

### Free tier

- Chat with locally downloaded models (any GGUF).
- RAG over a single user-chosen folder.
- `nomic-embed-text v2` embeddings.
- PDF / Markdown / code parsing.
- Auto-updates, Sparkle delta updates.

### Pro tier (€49 one-time)

- Multiple folders + Apple Notes integration.
- FSEvents incremental re-index.
- `mxbai-embed-large` upgraded embeddings.
- Shortcuts.app intents + menu bar quick-access.
- Cloud BYOK fallback (Claude, OpenAI) via Keychain — explicitly opt-in.
- iCloud chat history sync via CloudKit.

## Alternatives considered

- **Fully closed-source binary**: maximizes revenue control but burns trust with the target audience.
- **Source-available paid (BUSL / Fair Source)**: shifts a percentage of would-be contributors and a non-trivial slice of /r/LocalLLaMA goodwill.
- **Fully open-source + GitHub Sponsors**: typical revenue for projects of this size in 2026 is €5-15k/year — insufficient to fund full-time development.

## Consequences

- Anyone can compile a "Pro-unlocked" build locally by stubbing the entitlement check. We accept this. Most paying customers prefer to pay rather than maintain a personal fork.
- The license-check code itself is open and auditable; we explicitly document what is sent to Lemon Squeezy (license key, optional device name) and what is not (no files, no prompts, no usage data).
- Pro features must add genuine value rather than gate basic functionality — anti-pattern explicitly forbidden in the project's marketing plan.
- Pricing is fixed for the lifetime of v1.x. Major-version upgrades (v2.0) may require a separate upgrade purchase, decided closer to that point.
