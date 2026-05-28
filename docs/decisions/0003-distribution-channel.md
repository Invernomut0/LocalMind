# ADR-0003 — Distribution Channel

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** founder

## Context

LocalMind needs a distribution channel that:

- Supports embedded native binaries (llama.cpp xcframework), recursive filesystem access (RAG over user folders), and subprocess invocation (`pandoc` for DOCX).
- Has reasonable install UX for non-developer users.
- Lets the founder keep 100% of revenue net of payment processor fees.
- Supports rapid release cadence without third-party review delays.

## Decision

LocalMind is distributed **outside the Mac App Store**, via:

1. **GitHub Releases** as the canonical download surface.
2. A **signed `.dmg`** (Apple Developer ID, hardened runtime, notarized via `notarytool`, stapled).
3. **Sparkle 2** with an EdDSA-signed `appcast.xml` for in-app updates (separate `appcast-beta.xml` for the beta channel).
4. A **landing page** on GitHub Pages (`Website/` directory) that links to the latest release.
5. A future **Homebrew Cask** submission once v1.0 is stable.

### What this enables

- Embedded `llama.cpp` xcframework with Metal backend — would be rejected by MAS.
- Direct access to user-chosen folders via security-scoped bookmarks rather than sandbox containers.
- Subprocess invocation of `pandoc` for DOCX parsing.
- No 30% App Store cut.
- No review delays for security or RAG bugfixes.

### What this costs

- Apple Developer Program enrollment is mandatory (~€99/year) for code signing and notarization. Without it, Gatekeeper blocks the app for end users.
- We must operate our own update mechanism (Sparkle).
- We give up automatic App Store discovery; marketing is entirely our responsibility (see the project's marketing plan).
- First-launch UX has a Gatekeeper prompt — mitigated by clear install instructions on the landing page.

## Alternatives considered

- **Mac App Store**: ruled out by MAS sandboxing limits. Embedded native binaries and arbitrary filesystem reads are incompatible with MAS policies.
- **Setapp**: revenue share + competing distribution channel. Considered for post-v1.0 evaluation but not for launch; it would split the audience and confuse the open-core narrative.
- **Direct download from own infrastructure**: more setup overhead than GitHub Releases buys. We keep release artifacts on GitHub and use a static landing page for marketing.

## Consequences

- Releases are produced by a single GitHub Actions workflow (`release.yml`) that builds, signs, notarizes, staples, generates a DMG, signs the appcast entry, and publishes the release. The workflow is the source of truth for what users download.
- We must protect the Apple Developer ID and the Sparkle EdDSA private key. Both live in GitHub Secrets; no copy is committed.
- Beta and stable channels are separate: `appcast-beta.xml` and `appcast.xml`. Users opt into beta in Settings.
