import XCTest
@testable import LocalMindCore

final class ModelCatalogTests: XCTestCase {
    override func tearDown() {
        RemoteCatalogURLProtocol.handler = nil
        super.tearDown()
    }

    func testBundledCatalogLoadsAtLeastQwenSmoke() async throws {
        let catalog = BundledModelCatalog()
        let document = try await catalog.load()
        XCTAssertEqual(document.schemaVersion, ModelCatalogDocument.supportedSchemaVersion)
        XCTAssertFalse(document.models.isEmpty)
        let qwen = document.models.first { $0.id.contains("qwen2.5-0.5b") }
        XCTAssertNotNil(qwen, "Expected Qwen 2.5 0.5B baseline entry in the bundled catalog")
        XCTAssertEqual(qwen?.family, .qwen)
        XCTAssertEqual(qwen?.promptTemplate, .chatML)
    }

    func testBundledCatalogContainsCuratedRecentFamilies() async throws {
        let catalog = BundledModelCatalog()
        let document = try await catalog.load()

        XCTAssertGreaterThanOrEqual(document.models.count, 8)
        XCTAssertTrue(document.models.contains { $0.id == "qwen2.5-7b-instruct-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "qwen3-4b-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "qwen3-8b-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "llama-3.2-3b-instruct-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "phi-4-mini-instruct-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "gemma-3-4b-it-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "ministral-8b-instruct-2410-q4_k_m" })

        let families = Set(document.models.map(\.family))
        XCTAssertTrue(families.isSuperset(of: [.qwen, .llama, .phi, .gemma, .mistral]))
    }

    func testBundledCatalogMatchesInstalledAndSourceFilenames() async throws {
        let catalog = BundledModelCatalog()
        let document = try await catalog.load()

        let installedURL = URL(fileURLWithPath: "/tmp/phi-4-mini-instruct-q4_k_m.gguf")
        let sourceURL = URL(fileURLWithPath: "/tmp/Phi-4-mini-instruct-Q4_K_M.gguf")

        XCTAssertEqual(document.entry(matchingModelURL: installedURL)?.id, "phi-4-mini-instruct-q4_k_m")
        XCTAssertEqual(document.entry(matchingModelURL: sourceURL)?.id, "phi-4-mini-instruct-q4_k_m")
        XCTAssertEqual(document.entry(matchingModelURL: sourceURL)?.promptTemplate, .phi)
    }

    func testEntryFindsInstalledModelUsingManagedAndSourceFilenames() throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let entry = ModelCatalogEntry(
            id: "phi-4-mini-instruct-q4_k_m",
            displayName: "Phi 4 Mini Instruct",
            family: .phi,
            parameterCount: "3.8B",
            quantization: "Q4_K_M",
            downloadURL: URL(string: "https://example.com/phi4-mini-original.gguf")!,
            sha256: String(repeating: "a", count: 64),
            sizeBytes: 1024,
            ramMinGB: 8,
            promptTemplate: .phi
        )

        let sourceURL = tempDir.appending(path: "phi4-mini-original.gguf")
        XCTAssertNil(entry.installedModelURL(in: tempDir))

        FileManager.default.createFile(atPath: sourceURL.path, contents: Data())
        XCTAssertEqual(entry.installedModelURL(in: tempDir), sourceURL)
        XCTAssertTrue(entry.matches(localModelURL: sourceURL))

        let managedURL = tempDir.appending(path: "phi-4-mini-instruct-q4_k_m.gguf")
        FileManager.default.createFile(atPath: managedURL.path, contents: Data())
        XCTAssertEqual(entry.installedModelURL(in: tempDir), managedURL)
        XCTAssertTrue(entry.matches(localModelURL: managedURL))
    }

    func testBundledCatalogShipsQwen3EntriesAgainAfterRuntimeUpgrade() async throws {
        let catalog = BundledModelCatalog()
        let document = try await catalog.load()

        XCTAssertTrue(document.models.contains { $0.id == "qwen3-4b-q4_k_m" })
        XCTAssertTrue(document.models.contains { $0.id == "qwen3-8b-q4_k_m" })
    }

    func testDecodingRejectsFutureSchemaVersion() async {
        let json = #"{"schemaVersion": 999, "updatedAt": "2026-05-28T00:00:00Z", "models": []}"#
        let catalog = StubCatalog(jsonString: json)
        do {
            _ = try await catalog.load()
            XCTFail("Expected schemaVersionTooNew")
        } catch ModelCatalogError.schemaVersionTooNew(let found, let supported) {
            XCTAssertEqual(found, 999)
            XCTAssertEqual(supported, ModelCatalogDocument.supportedSchemaVersion)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEntryDecodingLowercasesSHAAndDefaultsContextLength() throws {
        let json = """
        {
            "id": "x",
            "displayName": "X",
            "family": "qwen",
            "parameterCount": "0.5B",
            "quantization": "Q4_K_M",
            "downloadURL": "https://example.com/x.gguf",
            "sha256": "ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
            "sizeBytes": 1024,
            "ramMinGB": 4,
            "promptTemplate": "chatML"
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ModelCatalogEntry.self, from: json)
        XCTAssertEqual(entry.sha256, "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789")
        XCTAssertEqual(entry.contextLength, 2048)
        XCTAssertNil(entry.notes)
    }

    func testRemoteCatalogFetchesAndCachesDocument() async throws {
        let payload = #"{"schemaVersion":1,"updatedAt":"2026-05-28T00:00:00Z","models":[{"id":"remote-qwen","displayName":"Remote Qwen","family":"qwen","parameterCount":"0.5B","quantization":"Q4_K_M","downloadURL":"https://example.com/remote.gguf","sha256":"abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789","sizeBytes":1024,"ramMinGB":4,"promptTemplate":"chatML"}]}"#
        let data = try XCTUnwrap(payload.data(using: .utf8))
        RemoteCatalogURLProtocol.handler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://localmind.app/catalog/v1/catalog.json")!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!,
                data
            )
        }

        let cacheFileURL = FileManager.default.temporaryDirectory
            .appending(path: "remote-catalog-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: cacheFileURL) }

        let catalog = RemoteModelCatalog(
            session: makeRemoteCatalogSession(),
            cacheFileURL: cacheFileURL,
            cacheTTL: 3600
        )

        let document = try await catalog.load()
        XCTAssertEqual(document.models.map(\.id), ["remote-qwen"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheFileURL.path))

        RemoteCatalogURLProtocol.handler = { _ in
            XCTFail("Fresh cache should avoid a second network request")
            return (HTTPURLResponse(), Data())
        }

        let secondDocument = try await catalog.load()
        XCTAssertEqual(secondDocument.models.map(\.id), ["remote-qwen"])
    }

    func testFallbackCatalogUsesBundledWhenRemoteFails() async throws {
        RemoteCatalogURLProtocol.handler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://localmind.app/catalog/v1/catalog.json")!,
                    statusCode: 503,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!,
                Data()
            )
        }

        let cacheFileURL = FileManager.default.temporaryDirectory
            .appending(path: "remote-catalog-fallback-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: cacheFileURL) }

        let primary = RemoteModelCatalog(
            session: makeRemoteCatalogSession(),
            cacheFileURL: cacheFileURL
        )
        let catalog = FallbackModelCatalog(primary: primary, fallback: BundledModelCatalog())

        let document = try await catalog.load()
        XCTAssertFalse(document.models.isEmpty)
        XCTAssertNotNil(document.models.first { $0.id.contains("qwen2.5-0.5b") })
    }

    private func makeRemoteCatalogSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RemoteCatalogURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private struct StubCatalog: ModelCatalog {
    let jsonString: String
    func load() async throws -> ModelCatalogDocument {
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(ModelCatalogDocument.self, from: data)
        if document.schemaVersion > ModelCatalogDocument.supportedSchemaVersion {
            throw ModelCatalogError.schemaVersionTooNew(
                found: document.schemaVersion,
                supported: ModelCatalogDocument.supportedSchemaVersion
            )
        }
        return document
    }
}

private final class RemoteCatalogURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "RemoteCatalogURLProtocol", code: 0))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
