import Foundation

public struct ModelDescriptor: Sendable, Hashable, Codable {
    public let id: String
    public let displayName: String
    public let parameterCount: String
    public let quantization: String
    public let sha256: String
    public let downloadURL: URL
    public let sizeBytes: Int64

    public init(
        id: String,
        displayName: String,
        parameterCount: String,
        quantization: String,
        sha256: String,
        downloadURL: URL,
        sizeBytes: Int64
    ) {
        self.id = id
        self.displayName = displayName
        self.parameterCount = parameterCount
        self.quantization = quantization
        self.sha256 = sha256
        self.downloadURL = downloadURL
        self.sizeBytes = sizeBytes
    }
}

public protocol ModelManager: Sendable {
    func availableModels() async throws -> [ModelDescriptor]
    func installedModels() async throws -> [ModelDescriptor]
    func install(_ descriptor: ModelDescriptor) async throws
    func remove(_ descriptor: ModelDescriptor) async throws
}
