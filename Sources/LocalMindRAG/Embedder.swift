import Foundation

public protocol Embedder: Sendable {
    var dimension: Int { get }
    func embed(_ texts: [String]) async throws -> [[Float]]
}
