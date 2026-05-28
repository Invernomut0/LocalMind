import Foundation

public struct ChatMessage: Sendable, Equatable, Identifiable {
    public enum Role: String, Sendable, Codable {
        case system, user, assistant
    }

    public let id: UUID
    public let role: Role
    public let content: String
    public let createdAt: Date

    public init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = .init()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

public protocol ChatEngine: Sendable {
    func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}
