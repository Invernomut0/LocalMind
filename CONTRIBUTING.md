# Contributing to LocalMind

LocalMind is open-core: the client is MIT-licensed and welcomes contributions. Pro features (paywalled) are gated by entitlement checks but their source remains in the same repository so the project stays auditable.

## Quick start

```bash
git clone https://github.com/Invernomut0/LocalMind.git
cd LocalMind
swift build
swift test
```

Requires Xcode 15+ / Swift 5.9+ and macOS 14+.

## How to contribute

- **Bug reports**: open an issue with the bug template. Include macOS version, hardware, repro steps.
- **Feature ideas**: start a thread under GitHub Discussions first. We use ADRs (`docs/decisions/`) for any architectural change.
- **Small fixes** (typo, doc, minor bug): open a PR directly.
- **Large changes**: discuss in an issue or Discussion first to avoid wasted work.

## Coding standards

- Swift 5.9+ idiomatic style.
- `SwiftFormat` + `SwiftLint` enforced in CI (configs at repo root, added in Sprint 0).
- Default to no comments. Only write a comment when the *why* is non-obvious.
- All code, comments, commit messages, and docs are in English.
- Public API needs DocC-compatible doc comments where it crosses module boundaries.

## Commit messages

Imperative mood, present tense. Conventional-style prefixes encouraged but not enforced:

```
feat(rag): add incremental FSEvents re-indexing
fix(license): handle clock-rollback in grace period check
docs(adr): record decision on DMG vs ZIP distribution
```

Reference an issue or ADR when relevant.

## Branching

- `main` is protected and always green.
- Feature branches: `feat/<short-slug>`.
- Releases tagged `vMAJOR.MINOR.PATCH[-prerelease]`.

## Tests

- New non-trivial code ships with tests.
- Coverage gates: ≥60% on `LocalMindCore`, `LocalMindRAG`, `LocalMindLicense`.
- Snapshot tests for SwiftUI views that gate user flows (paywall, onboarding).

## ADRs

Architectural decisions go in `docs/decisions/NNNN-slug.md`. Follow the format of existing ADRs. PRs that change architecture without an ADR will be asked to add one.

## Community

- Be respectful — see [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md).
- Long-form discussion: GitHub Discussions.
- Synchronous chat: Discord (link added at v1.0 launch).
