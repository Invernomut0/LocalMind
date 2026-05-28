import XCTest
@testable import LocalMindRAG

final class IndexerTests: XCTestCase {
    func testIndexedChunkRoundTrips() {
        let url = URL(fileURLWithPath: "/tmp/example.pdf")
        let chunk = IndexedChunk(sourcePath: url, pageNumber: 2, text: "Hello world.")
        XCTAssertEqual(chunk.sourcePath, url)
        XCTAssertEqual(chunk.pageNumber, 2)
        XCTAssertEqual(chunk.text, "Hello world.")
    }
}
