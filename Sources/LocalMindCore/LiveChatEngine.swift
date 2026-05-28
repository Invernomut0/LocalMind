import Foundation

public final class LiveChatEngine: ChatEngine, @unchecked Sendable {
    private let backend: any InferenceBackend
    private let builder: PromptBuilder
    private let defaultSystemPrompt: String?
    private let template: PromptTemplate

    public init(
        backend: any InferenceBackend,
        builder: PromptBuilder = PromptBuilder(),
        defaultSystemPrompt: String? = nil,
        template: PromptTemplate = .chatML
    ) {
        self.backend = backend
        self.builder = builder
        self.defaultSystemPrompt = defaultSystemPrompt
        self.template = template
    }

    public func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        let request: InferenceRequest
        do {
            request = try builder.makeRequest(
                history: history,
                systemPrompt: defaultSystemPrompt,
                template: template
            )
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
        return backend.generate(request)
    }
}
