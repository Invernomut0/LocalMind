import Foundation

public enum InferenceBackendKind: String, Sendable, Codable {
    case llamaCPP
    case mlx
}

public enum PromptTemplate: String, Sendable, Codable {
    case chatML
    case llama
    case llama3
    case mistral
    case phi
    case gemma
    case alpaca
}

public struct ChatTurn: Sendable, Equatable {
    public let user: String
    public let assistant: String

    public init(user: String, assistant: String) {
        self.user = user
        self.assistant = assistant
    }
}

public struct InferenceRequest: Sendable {
    public let systemPrompt: String?
    public let userMessage: String
    public let history: [ChatTurn]
    public let template: PromptTemplate
    public let maxTokens: Int
    public let temperature: Double
    public let topP: Double
    public let stopSequences: [String]

    public init(
        systemPrompt: String? = nil,
        userMessage: String,
        history: [ChatTurn] = [],
        template: PromptTemplate = .chatML,
        maxTokens: Int = 1024,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        stopSequences: [String] = []
    ) {
        self.systemPrompt = systemPrompt
        self.userMessage = userMessage
        self.history = history
        self.template = template
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.stopSequences = stopSequences
    }
}

public protocol InferenceBackend: Sendable {
    var kind: InferenceBackendKind { get }
    func loadModel(at url: URL) async throws
    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<String, Error>
}
