import Foundation

public protocol SecurityScopedBookmarkStore: Sendable {
    func store(url: URL) async throws
    func resolveAll() async throws -> [URL]
    func forget(url: URL) async throws
}
