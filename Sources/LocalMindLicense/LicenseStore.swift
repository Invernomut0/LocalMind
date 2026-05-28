import Foundation

public struct LicenseRecord: Sendable, Codable, Equatable {
    public let key: String
    public let email: String
    public let issuedAt: Date
    public let lastVerifiedAt: Date

    public init(key: String, email: String, issuedAt: Date, lastVerifiedAt: Date) {
        self.key = key
        self.email = email
        self.issuedAt = issuedAt
        self.lastVerifiedAt = lastVerifiedAt
    }
}

public protocol LicenseStore: Sendable {
    func load() async throws -> LicenseRecord?
    func save(_ record: LicenseRecord) async throws
    func clear() async throws
}
