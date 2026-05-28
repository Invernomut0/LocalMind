import XCTest
@testable import LocalMindCore

final class ModelCatalogTests: XCTestCase {
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
