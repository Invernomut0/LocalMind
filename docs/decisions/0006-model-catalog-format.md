# ADR-0006 — Model catalog format

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** founder
- **Relates to:** [ADR-0001](./0001-tech-stack.md) (llama.cpp + GGUF) · [ADR-0005](./0005-vendor-swiftllama.md) (vendored prompt templates)

## Context

Sprint 2 needs an in-app model catalog so first-run users don't have to drop a `.gguf` into a folder by hand. The catalog has to:

- Survive an offline first launch (no "couldn't reach github.io").
- Be safe to evolve (add a model, retire a model, fix a SHA) without forcing a client release.
- Tell the app enough about each model to pick the right prompt template (Qwen, Llama 3, Phi, Mistral, Gemma, generic ChatML), to estimate disk + RAM, and to gate the download (SHA-256, size).

Per the operating plan the long-term host is GitHub Pages with a versioned URL. For this sprint we **ship a bundled `catalog.json` inside the app** and treat the remote URL as a future optimization. That keeps the first-run flow hermetic.

## Decision

The catalog is a single JSON file with this top-level shape:

```json
{
    "schemaVersion": 1,
    "updatedAt": "2026-05-28T00:00:00Z",
    "models": [ { ... }, ... ]
}
```

Each `models[i]` entry follows this schema:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | Stable, kebab-case, e.g. `qwen2.5-0.5b-instruct-q4_k_m`. Used as a key in the install index. |
| `displayName` | string | yes | Human-friendly name shown in the picker. |
| `family` | string | yes | One of `qwen`, `llama`, `mistral`, `phi`, `gemma`, `other`. Drives the prompt template. |
| `parameterCount` | string | yes | Human label, e.g. `"0.5B"`, `"3B"`. Not parsed. |
| `quantization` | string | yes | E.g. `Q4_K_M`. Not parsed. |
| `downloadURL` | string (URL) | yes | Direct HTTPS link to the `.gguf`. Hugging Face raw resolve URLs are fine. |
| `sha256` | string (64 hex) | yes | Lowercase hex digest of the file body. Download is rejected on mismatch. |
| `sizeBytes` | integer | yes | Expected file size in bytes. Used for progress UI and disk-space pre-check. |
| `ramMinGB` | integer | yes | Practical minimum RAM for usable throughput on Apple Silicon. The picker can dim entries above the host RAM. |
| `promptTemplate` | string | yes | One of the cases of `PromptTemplate` (`chatML`, `llama`, `llama3`, `mistral`, `phi`, `gemma`, `alpaca`). |
| `contextLength` | integer | optional | Native training context. Defaults to 2048 if absent. |
| `notes` | string | optional | One-line description shown under the name. |

`schemaVersion` lets us evolve fields later without silent data loss; the client refuses catalogs with a higher schemaVersion than it knows about, prompting an update.

## Where the catalog lives

- **Bundled** at `Resources/Models/catalog.json`, loaded via `Bundle.module` for the `LocalMindCore` target. Resources are declared in `Package.swift` with `.process("Resources")`.
- **Future remote**: `https://localmind.app/catalog/v1/catalog.json` (or equivalent on GH Pages). Sprint 3 wires a `RemoteModelCatalog` that fetches this URL with a short cache TTL, falling back to the bundled copy on any error.

## Curated baseline

For v0.2.0-alpha the bundled catalog must include at least:

- Qwen 2.5 0.5B Instruct Q4_K_M — the tiny smoke-test target, the model the founder already tested with.
- Qwen 2.5 3B Instruct Q4_K_M — sweet-spot for 16 GB Macs.
- Llama 3.2 1B Instruct Q4_K_M and Llama 3.2 3B Instruct Q4_K_M — `llama3` template coverage.
- Phi 3.5 Mini Instruct Q4_K_M — `phi` template coverage.
- Mistral 7B Instruct v0.3 Q4_K_M — for 24 GB+ Macs.

We will not chase coverage of every quant; one Q4_K_M variant per family is enough at this stage.

## Consequences

- **Trust model**: with bundled `sha256` values the client refuses tampered downloads even when fetched from a third-party mirror. This is the security primitive we rely on while we host nothing ourselves.
- **Update cadence**: until we ship a remote catalog, adding a new model requires a client release. Acceptable trade-off for Sprint 2; revisited in Sprint 3.
- **Catalog drift**: the catalog format and the `PromptTemplate` enum live in two repositories conceptually (the client's source and the future remote JSON). Schema additions must be backward-compatible (always optional, never required) so older clients keep working.
- **Hugging Face dependency**: most curated entries point at Hugging Face `resolve` URLs. If HF changes the public download policy we point the catalog at mirrored copies (BunnyCDN, ~€5/month, called out as risk R10 in the operating plan).
