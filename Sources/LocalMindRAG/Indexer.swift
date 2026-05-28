import Foundation

public struct IndexedChunk: Sendable, Hashable {
    public let id: UUID
    public let sourcePath: URL
    public let pageNumber: Int?
    public let text: String

    public init(id: UUID = UUID(), sourcePath: URL, pageNumber: Int? = nil, text: String) {
        self.id = id
        self.sourcePath = sourcePath
        self.pageNumber = pageNumber
        self.text = text
    }
}

public protocol Indexer: Sendable {
    func index(folder: URL) -> AsyncThrowingStream<IndexProgress, Error>
}

public struct IndexProgress: Sendable {
    public let filesProcessed: Int
    public let totalFiles: Int
    public let chunksWritten: Int
    public let currentFile: URL?
}
