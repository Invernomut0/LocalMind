import Foundation

public enum InferenceBackendKind: String, Sendable, Codable {
    case llamaCPP
    case mlx
}

public struct InferenceRequest: Sendable {
    public let prompt: String
    public let maxTokens: Int
    public let temperature: Double
    public let topP: Double
    public let stopSequences: [String]

    public init(
        prompt: String,
        maxTokens: Int = 1024,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        stopSequences: [String] = []
    ) {
        self.prompt = prompt
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.stopSequences = stopSequences
    }
}

public protocol InferenceBackend: Sendable {
    var kind: InferenceBackendKind { get }
    func loadModel(at path: URL) async throws
    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<String, Error>
}
