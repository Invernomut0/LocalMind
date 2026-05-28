import Foundation
import SwiftLlama

public final class LlamaInferenceBackend: InferenceBackend, @unchecked Sendable {
    public let kind: InferenceBackendKind = .llamaCPP

    private let lock = NSLock()
    private var swiftLlama: SwiftLlama?
    private var loadedModelURL: URL?

    public init() {}

    public func loadModel(at url: URL) async throws {
        let llama = try SwiftLlama(modelPath: url.path)
        lock.withLock {
            self.swiftLlama = llama
            self.loadedModelURL = url
        }
    }

    public var currentModelURL: URL? {
        lock.withLock { loadedModelURL }
    }

    public func generate(_ request: InferenceRequest) -> AsyncThrowingStream<String, Error> {
        let maybeLlama = lock.withLock { self.swiftLlama }
        guard let llama = maybeLlama else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LlamaInferenceBackendError.modelNotLoaded)
            }
        }
        let capture = SwiftLlamaCapture(
            llama: llama,
            prompt: Prompt(
                type: request.template.swiftLlamaType,
                systemPrompt: request.systemPrompt ?? "",
                userMessage: request.userMessage,
                history: request.history.map { Chat(user: $0.user, bot: $0.assistant) }
            )
        )
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stream: AsyncThrowingStream<String, Error> = await capture.llama.start(for: capture.prompt)
                    for try await chunk in stream {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

public enum LlamaInferenceBackendError: Error, Equatable {
    case modelNotLoaded
}

// Swift 6 strict concurrency: SwiftLlama and Prompt are not declared Sendable, but
// every public SwiftLlama method is `@SwiftLlamaActor`-isolated so concurrent access
// is serialized there. Prompt is an immutable value struct of String fields. This box
// lets us hand both into a `Task` without tripping Sendable checks.
private struct SwiftLlamaCapture: @unchecked Sendable {
    let llama: SwiftLlama
    let prompt: Prompt
}

private extension PromptTemplate {
    var swiftLlamaType: Prompt.`Type` {
        switch self {
        case .chatML: return .chatML
        case .llama: return .llama
        case .llama3: return .llama3
        case .mistral: return .mistral
        case .phi: return .phi
        case .gemma: return .gemma
        case .alpaca: return .alpaca
        }
    }
}
