import Foundation

public struct ModelCatalogEntry: Sendable, Codable, Equatable, Identifiable, Hashable {
    public enum Family: String, Sendable, Codable {
        case qwen, llama, mistral, phi, gemma, other
    }

    public let id: String
    public let displayName: String
    public let family: Family
    public let parameterCount: String
    public let quantization: String
    public let downloadURL: URL
    public let sha256: String
    public let sizeBytes: Int64
    public let ramMinGB: Int
    public let promptTemplate: PromptTemplate
    public let contextLength: Int
    public let notes: String?

    public init(
        id: String,
        displayName: String,
        family: Family,
        parameterCount: String,
        quantization: String,
        downloadURL: URL,
        sha256: String,
        sizeBytes: Int64,
        ramMinGB: Int,
        promptTemplate: PromptTemplate,
        contextLength: Int = 2048,
        notes: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.family = family
        self.parameterCount = parameterCount
        self.quantization = quantization
        self.downloadURL = downloadURL
        self.sha256 = sha256.lowercased()
        self.sizeBytes = sizeBytes
        self.ramMinGB = ramMinGB
        self.promptTemplate = promptTemplate
        self.contextLength = contextLength
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case id, displayName, family, parameterCount, quantization, downloadURL, sha256, sizeBytes, ramMinGB, promptTemplate, contextLength, notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.family = try container.decode(Family.self, forKey: .family)
        self.parameterCount = try container.decode(String.self, forKey: .parameterCount)
        self.quantization = try container.decode(String.self, forKey: .quantization)
        self.downloadURL = try container.decode(URL.self, forKey: .downloadURL)
        self.sha256 = try container.decode(String.self, forKey: .sha256).lowercased()
        self.sizeBytes = try container.decode(Int64.self, forKey: .sizeBytes)
        self.ramMinGB = try container.decode(Int.self, forKey: .ramMinGB)
        self.promptTemplate = try container.decode(PromptTemplate.self, forKey: .promptTemplate)
        self.contextLength = try container.decodeIfPresent(Int.self, forKey: .contextLength) ?? 2048
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

public struct ModelCatalogDocument: Sendable, Codable, Equatable {
    public static let supportedSchemaVersion = 1

    public let schemaVersion: Int
    public let updatedAt: Date
    public let models: [ModelCatalogEntry]

    public init(schemaVersion: Int, updatedAt: Date, models: [ModelCatalogEntry]) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.models = models
    }

    public func entry(matchingModelURL url: URL) -> ModelCatalogEntry? {
        let candidateNames = Set([
            url.lastPathComponent.lowercased(),
            url.deletingPathExtension().lastPathComponent.lowercased()
        ])

        return models.first { entry in
            let installedName = "\(entry.id).gguf".lowercased()
            let sourceName = entry.downloadURL.lastPathComponent.lowercased()
            return candidateNames.contains(installedName)
                || candidateNames.contains(entry.id.lowercased())
                || candidateNames.contains(sourceName)
        }
    }
}

public protocol ModelCatalog: Sendable {
    func load() async throws -> ModelCatalogDocument
}

public enum ModelCatalogError: Error, Equatable {
    case resourceMissing(String)
    case schemaVersionTooNew(found: Int, supported: Int)
    case decodingFailed(String)
    case remoteFetchFailed(String)
}

public struct BundledModelCatalog: ModelCatalog {
    private let resourceName: String
    private let bundles: [Bundle]

    public init() {
        self.init(resourceName: "catalog", bundles: Self.defaultLookupBundles())
    }

    public init(resourceName: String, bundle: Bundle) {
        self.resourceName = resourceName
        self.bundles = [bundle]
    }

    public init(resourceName: String, bundles: [Bundle]) {
        self.resourceName = resourceName
        self.bundles = bundles
    }

    /// `Bundle.module` works out of the box for `swift run` / `swift test`,
    /// but inside a real `.app` macOS code signing forbids unsealed contents
    /// at the bundle root (where SwiftPM expects its generated resource
    /// bundle). The fallback finds the SPM bundle inside Contents/Resources/.
    private static func defaultLookupBundles() -> [Bundle] {
        var result: [Bundle] = [.module]
        if let url = Bundle.main.url(forResource: "LocalMind_LocalMindCore", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            result.append(bundle)
        }
        return result
    }

    public func load() async throws -> ModelCatalogDocument {
        let url = bundles.lazy.compactMap { bundle in
            bundle.url(forResource: self.resourceName, withExtension: "json", subdirectory: "Models")
                ?? bundle.url(forResource: self.resourceName, withExtension: "json")
        }.first
        guard let url else {
            throw ModelCatalogError.resourceMissing(resourceName + ".json")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document: ModelCatalogDocument
        do {
            document = try decoder.decode(ModelCatalogDocument.self, from: data)
        } catch {
            throw ModelCatalogError.decodingFailed(String(describing: error))
        }
        if document.schemaVersion > ModelCatalogDocument.supportedSchemaVersion {
            throw ModelCatalogError.schemaVersionTooNew(
                found: document.schemaVersion,
                supported: ModelCatalogDocument.supportedSchemaVersion
            )
        }
        return document
    }
}

public struct RemoteModelCatalog: ModelCatalog, @unchecked Sendable {
    public static let defaultURL = URL(string: "https://localmind.app/catalog/v1/catalog.json")!

    private let url: URL
    private let session: URLSession
    private let cacheFileURL: URL
    private let cacheTTL: TimeInterval
    private let now: @Sendable () -> Date

    public init(
        url: URL = RemoteModelCatalog.defaultURL,
        session: URLSession = .shared,
        fileManager: FileManager = .default,
        cacheFileURL: URL? = nil,
        cacheTTL: TimeInterval = 60 * 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.url = url
        self.session = session
        self.cacheTTL = cacheTTL
        self.now = now

        if let cacheFileURL {
            self.cacheFileURL = cacheFileURL
        } else {
            let cachesDir = (try? fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let appDir = cachesDir.appendingPathComponent("LocalMind")
            self.cacheFileURL = appDir.appendingPathComponent("remote-catalog.json")
        }
    }

    public func load() async throws -> ModelCatalogDocument {
        if let cached = try loadCachedDocumentIfFresh() {
            return cached
        }

        do {
            let document = try await fetchRemoteDocument()
            try persistCache(document)
            return document
        } catch {
            if let cached = try loadCachedDocumentAllowingStale() {
                return cached
            }
            throw error
        }
    }

    private func fetchRemoteDocument() async throws -> ModelCatalogDocument {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ModelCatalogError.remoteFetchFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModelCatalogError.remoteFetchFailed("Invalid response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ModelCatalogError.remoteFetchFailed("HTTP \(httpResponse.statusCode)")
        }

        return try decodeDocument(from: data)
    }

    private func loadCachedDocumentIfFresh() throws -> ModelCatalogDocument? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return nil
        }
        let values = try cacheFileURL.resourceValues(forKeys: [.contentModificationDateKey])
        if let modifiedAt = values.contentModificationDate,
           now().timeIntervalSince(modifiedAt) <= cacheTTL {
            let data = try Data(contentsOf: cacheFileURL)
            return try decodeDocument(from: data)
        }
        return nil
    }

    private func loadCachedDocumentAllowingStale() throws -> ModelCatalogDocument? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: cacheFileURL)
        return try decodeDocument(from: data)
    }

    private func persistCache(_ document: ModelCatalogDocument) throws {
        let dir = cacheFileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(document)
        try data.write(to: cacheFileURL, options: [.atomic])
    }

    private func decodeDocument(from data: Data) throws -> ModelCatalogDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document: ModelCatalogDocument
        do {
            document = try decoder.decode(ModelCatalogDocument.self, from: data)
        } catch {
            throw ModelCatalogError.decodingFailed(String(describing: error))
        }
        if document.schemaVersion > ModelCatalogDocument.supportedSchemaVersion {
            throw ModelCatalogError.schemaVersionTooNew(
                found: document.schemaVersion,
                supported: ModelCatalogDocument.supportedSchemaVersion
            )
        }
        return document
    }
}

public struct FallbackModelCatalog: ModelCatalog {
    private let primary: any ModelCatalog
    private let fallback: any ModelCatalog

    public init(primary: any ModelCatalog, fallback: any ModelCatalog) {
        self.primary = primary
        self.fallback = fallback
    }

    public func load() async throws -> ModelCatalogDocument {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()
        }
    }
}
