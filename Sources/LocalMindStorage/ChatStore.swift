import Foundation

public struct PersistedMessage: Sendable, Codable, Equatable, Identifiable {
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

public final class ChatStore: @unchecked Sendable {
    public static let defaultFileName = "conversation.json"

    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(fileURL: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let dir = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appending(path: "LocalMind", directoryHint: .isDirectory)
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appending(path: Self.defaultFileName, directoryHint: .notDirectory)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        self.encoder = encoder
        self.decoder = decoder
    }

    public var storageURL: URL { fileURL }

    public func load() throws -> [PersistedMessage] {
        lock.lock()
        defer { lock.unlock() }
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }
        return try decoder.decode([PersistedMessage].self, from: data)
    }

    public func save(_ messages: [PersistedMessage]) throws {
        lock.lock()
        defer { lock.unlock() }
        let data = try encoder.encode(messages)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
