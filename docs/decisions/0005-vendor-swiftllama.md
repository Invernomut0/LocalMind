# ADR-0005 — Vendor SwiftLlama 0.4.0 into Sources/Vendor/

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** founder
- **Relates to:** [ADR-0001](./0001-tech-stack.md) (SwiftLlama as the llama.cpp binding) · [ADR-0004](./0004-raise-macos-minimum.md) (macOS 15 to consume SwiftLlama 0.4.0)

## Context

Sprint 1 chat verification surfaced three upstream defects in [SwiftLlama 0.4.0](https://github.com/ShenghaiWang/SwiftLlama) that together make the library unusable for a Qwen 2.5 chat client out of the box:

1. **`llama.cpp` b5046 vocab API regression.** The bundled `llama.xcframework` (release `b5046`) ships the post-deprecation API where `llama_tokenize`, `llama_token_to_piece`, and `llama_token_is_eog` take a `const struct llama_vocab *` as the first argument. SwiftLlama's `LlamaModel` still passes a `llama_model *` opaque pointer. The Swift→C bridge accepts both as `OpaquePointer`, so the call compiles, but at runtime llama.cpp reinterprets the pointer as a vocab and the program crashes with `EXC_BAD_ACCESS / SIGBUS` inside `llama_vocab::impl::tokenize`. The crash is deterministic on the first message sent.

2. **Broken ChatML prompt encoder.** `Prompt.encodeChatMLPrompt()` emits literal stray double-quote characters (`"<|im_start|>user"`) and silently drops the system prompt. Even after fix #1, Qwen 2.5 responds by parroting the malformed scaffold — including the stray quotes — and never emits a clean `<|im_end|>`, breaking end-of-generation detection.

3. **Tokenization with `parse_special=false`.** Upstream passes `false` as the last argument to `llama_tokenize`, which means ChatML markers like `<|im_start|>` and `<|im_end|>` in the prompt are tokenized as the literal characters `<`, `|`, `im_start`, `|`, `>` rather than as the dedicated special-token vocab IDs the model was fine-tuned on. The model then generates its reply by mimicking the character pattern token-by-character ("C iao !  Come  pos so") and never emits the actual `<|im_end|>` special token, so `llama_vocab_is_eog` cannot stop generation.

Upstream is single-maintainer with the last release in July 2025 (~11 months ago). Filing issues and waiting for a release is not compatible with Sprint 1's calendar.

## Decision

Copy the SwiftLlama 0.4.0 sources into `Sources/Vendor/SwiftLlama/` and consume them as a local SPM target alongside the same `llama.xcframework` binaryTarget the upstream package used. The remote dependency on `ShenghaiWang/SwiftLlama` is removed; the dependency on the prebuilt `llama.cpp` xcframework (release `b5046`) is kept as a direct `binaryTarget` in our `Package.swift`.

Patches applied on top of the imported sources:

- `LlamaModel.swift`: cache `llama_model_get_vocab(model)` once at init, then pass the vocab pointer (not the model pointer) to `llama_tokenize`, `llama_token_to_piece`, and `llama_vocab_is_eog`. Also flip `parse_special` to `true` in the `llama_tokenize` call so ChatML markers in the prompt are recognized as their special-token IDs.
- `Models/Prompt.swift`: rewrite `encodeChatMLPrompt()` to emit a clean Qwen-compatible ChatML scaffold, including the system prompt when present, and using only literal `<|im_start|>` / `<|im_end|>` markers.
- `Models/TypeAlias.swift`: introduce a `Vocab` typealias for clarity.

The vendored files keep the upstream MIT `LICENSE` in `Sources/Vendor/SwiftLlama/LICENSE` and are excluded from the SPM target's sources list.

Other prompt encoders (`llama`, `llama3`, `mistral`, `phi`, `gemma`, `alpaca`) almost certainly suffer from the same class of bug as ChatML did (stray quotes, missing system prompt). They are NOT patched here — we will fix each one the first time the catalog ships a model that uses it.

## Consequences

**Accepted trade-offs:**

- ~600 LOC of third-party Swift now lives in the repo. Code reviewers should be aware that anything under `Sources/Vendor/` is upstream, not native.
- We diverge from upstream and must manually port any future SwiftLlama patches we care about. Mitigation: upstream is barely maintained, so divergence cost is low.
- The vendored target name is still `SwiftLlama`, matching the original module name. This keeps `import SwiftLlama` in our `LocalMindCore` unchanged.

**Gains:**

- The crash and the prompt-template bug are fixed today, not whenever an upstream release happens.
- Future Sprint 5 work (sqlite-vec, embeddings via llama.cpp embedding mode) can safely target the same vendored layer.
- We hold the upgrade rhythm — we choose when to bump the bundled `llama.cpp` xcframework, not the upstream library author.

**Reversibility:**

- Going back to remote SwiftLlama is one `Package.swift` change away. Keeping our patches as a clean diff atop upstream makes a future PR straightforward if upstream becomes responsive.

## Follow-ups

- Open an upstream issue + draft PR on `ShenghaiWang/SwiftLlama` covering the vocab API fix and the ChatML encoder rewrite. Cite this ADR.
- When we add a non-ChatML model to the catalog (Llama 3, Mistral, Phi, Gemma), audit the corresponding `encode*Prompt()` in `Sources/Vendor/SwiftLlama/Models/Prompt.swift` against the model's reference template and patch as needed.

## References

- Crash signature: `EXC_BAD_ACCESS (SIGBUS) at 0x000000110000011d`, top frames `llama_vocab::impl::tokenize` ← `llama_vocab::tokenize(char const*, ...)` ← `LlamaModel.tokenize(text:addBos:)`.
- Upstream sources: <https://github.com/ShenghaiWang/SwiftLlama/tree/v0.4.0>
- Bundled xcframework: <https://github.com/ggml-org/llama.cpp/releases/download/b5046/llama-b5046-xcframework.zip>
