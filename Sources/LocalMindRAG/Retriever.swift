import Foundation

public struct RetrievedContext: Sendable {
    public let chunk: IndexedChunk
    public let similarity: Float

    public init(chunk: IndexedChunk, similarity: Float) {
        self.chunk = chunk
        self.similarity = similarity
    }
}

public protocol Retriever: Sendable {
    func retrieve(query: String, topK: Int) async throws -> [RetrievedContext]
}
