import Foundation

public protocol Database: Sendable {
    func migrate() async throws
    func close() async
}

public enum DatabaseError: Error, Sendable {
    case migrationFailed(String)
    case unavailable
}
