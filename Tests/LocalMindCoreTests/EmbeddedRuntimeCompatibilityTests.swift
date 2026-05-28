import XCTest
@testable import LocalMindCore

final class EmbeddedRuntimeCompatibilityTests: XCTestCase {
    func testQwen3ModelIsMarkedUnsupported() {
        let checker = EmbeddedRuntimeCompatibilityChecker()

        let compatibility = checker.compatibility(
            forModelURL: URL(fileURLWithPath: "/tmp/qwen3-8b-q4_k_m.gguf")
        )

        XCTAssertFalse(compatibility.isSupported)
        XCTAssertNotNil(compatibility.reason)
    }

    func testQwen25ModelRemainsSupported() {
        let checker = EmbeddedRuntimeCompatibilityChecker()
        let entry = ModelCatalogEntry(
            id: "qwen2.5-7b-instruct-q4_k_m",
            displayName: "Qwen 2.5 7B Instruct",
            family: .qwen,
            parameterCount: "7B",
            quantization: "Q4_K_M",
            downloadURL: URL(string: "https://example.com/model.gguf")!,
            sha256: String(repeating: "a", count: 64),
            sizeBytes: 1024,
            ramMinGB: 16,
            promptTemplate: .chatML
        )

        let compatibility = checker.compatibility(for: entry)
        XCTAssertTrue(compatibility.isSupported)
        XCTAssertNil(compatibility.reason)
    }
}
