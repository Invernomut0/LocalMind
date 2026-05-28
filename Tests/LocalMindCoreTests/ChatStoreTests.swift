import XCTest
@testable import LocalMindStorage

final class ChatStoreTests: XCTestCase {
    func testRoundTripSavesAndLoadsMessages() throws {
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }

        // Use millisecond-precision dates so JSON round-trip is lossless.
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let t1 = Date(timeIntervalSince1970: 1_700_000_001)
        let store = try ChatStore(fileURL: url)
        let toSave = [
            PersistedMessage(role: .user, content: "Hello", createdAt: t0),
            PersistedMessage(role: .assistant, content: "Hi there", createdAt: t1)
        ]
        try store.save(toSave)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let store2 = try ChatStore(fileURL: url)
        let loaded = try store2.load()
        XCTAssertEqual(loaded, toSave)
    }

    func testLoadOnMissingFileReturnsEmpty() throws {
        let url = makeTempFile()
        let store = try ChatStore(fileURL: url)
        let loaded = try store.load()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testClearRemovesFile() throws {
        let url = makeTempFile()
        let store = try ChatStore(fileURL: url)
        try store.save([PersistedMessage(role: .user, content: "x")])
        try store.clear()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testSaveOverwritesPreviousContent() throws {
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = try ChatStore(fileURL: url)
        try store.save([PersistedMessage(role: .user, content: "first")])
        try store.save([PersistedMessage(role: .assistant, content: "second")])
        let loaded = try store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.content, "second")
    }

    private func makeTempFile() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "chatstore-\(UUID().uuidString).json")
    }
}
