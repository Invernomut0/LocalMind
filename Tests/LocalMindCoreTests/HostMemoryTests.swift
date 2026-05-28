import XCTest
@testable import LocalMindCore

final class HostMemoryTests: XCTestCase {
    func testDetectorReadsPhysicalMemoryBytes() {
        let detector = HostMemoryDetector(physicalMemoryBytesProvider: {
            16 * 1_073_741_824
        })

        let hostMemory = detector.current()
        XCTAssertEqual(hostMemory.physicalMemoryBytes, 16 * 1_073_741_824)
        XCTAssertEqual(hostMemory.physicalMemoryGB, 16)
    }

    func testRecommendationMarksModelAsRecommendedWhenHostMeetsMinimum() {
        let entry = makeEntry(ramMinGB: 8)
        let hostMemory = HostMemory(physicalMemoryBytes: 16 * 1_073_741_824)

        let recommendation = entry.ramRecommendation(for: hostMemory)
        XCTAssertTrue(recommendation.isRecommended)
        XCTAssertEqual(recommendation.suitability, .recommended)
        XCTAssertEqual(recommendation.minimumRAMGB, 8)
    }

    func testRecommendationReportsMissingRAMWhenHostIsUnderMinimum() {
        let entry = makeEntry(ramMinGB: 24)
        let hostMemory = HostMemory(physicalMemoryBytes: 16 * 1_073_741_824)

        let recommendation = entry.ramRecommendation(for: hostMemory)
        XCTAssertFalse(recommendation.isRecommended)
        XCTAssertEqual(recommendation.suitability, .constrained(missingGB: 8))
    }

    private func makeEntry(ramMinGB: Int) -> ModelCatalogEntry {
        ModelCatalogEntry(
            id: "fixture",
            displayName: "Fixture",
            family: .qwen,
            parameterCount: "3B",
            quantization: "Q4_K_M",
            downloadURL: URL(string: "https://example.com/model.gguf")!,
            sha256: String(repeating: "a", count: 64),
            sizeBytes: 1_024,
            ramMinGB: ramMinGB,
            promptTemplate: .chatML
        )
    }
}
