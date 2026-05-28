import Foundation

public struct VectorHit: Sendable {
    public let chunkID: UUID
    public let similarity: Float

    public init(chunkID: UUID, similarity: Float) {
        self.chunkID = chunkID
        self.similarity = similarity
    }
}

public protocol VectorStore: Sendable {
    func upsert(chunks: [(IndexedChunk, [Float])]) async throws
    func search(_ query: [Float], topK: Int) async throws -> [VectorHit]
    func deleteChunks(forSource path: URL) async throws
}
