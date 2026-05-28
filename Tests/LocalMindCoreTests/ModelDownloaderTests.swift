import CryptoKit
import XCTest
@testable import LocalMindCore

final class ModelDownloaderTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testDownloadSucceedsAndVerifies() async throws {
        let body = Data("hello".utf8)
        let expectedSHA = SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined()
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/test.gguf")!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Length": "\(body.count)"]
            )!
            return (response, body)
        }

        let entry = makeEntry(sha: expectedSHA, size: Int64(body.count))
        let downloader = makeDownloader()
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let recorder = ProgressRecorder()
        let dest = try await downloader.download(entry: entry, destinationDir: dir) { progress in
            recorder.record(progress)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
        XCTAssertEqual(try Data(contentsOf: dest), body)
        XCTAssertEqual(recorder.value?.bytesDownloaded, Int64(body.count))
    }

    func testChecksumMismatchRemovesDownloadedFile() async throws {
        let body = Data("hello".utf8)
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/test.gguf")!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Length": "\(body.count)"]
            )!
            return (response, body)
        }
        let entry = makeEntry(sha: String(repeating: "0", count: 64), size: Int64(body.count))
        let downloader = makeDownloader()
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        do {
            _ = try await downloader.download(entry: entry, destinationDir: dir) { _ in }
            XCTFail("Expected checksum mismatch")
        } catch ChecksumError.mismatch {
            // expected
        } catch {
            XCTFail("Unexpected: \(error)")
        }

        let dest = dir.appending(path: "\(entry.id).gguf")
        XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path), "Failed download should be cleaned up")
    }

    func testExistingFileWithMatchingChecksumIsSkipped() async throws {
        let body = Data("hello".utf8)
        let expectedSHA = SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined()
        let entry = makeEntry(sha: expectedSHA, size: Int64(body.count))

        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let dest = dir.appending(path: "\(entry.id).gguf")
        try body.write(to: dest)

        // No mock handler -- if we hit the network the URLSession will fail.
        MockURLProtocol.handler = { _ in
            XCTFail("Should not hit the network when file already matches")
            return (HTTPURLResponse(), Data())
        }

        let downloader = makeDownloader()
        let resolved = try await downloader.download(entry: entry, destinationDir: dir) { _ in }
        XCTAssertEqual(resolved.standardizedFileURL, dest.standardizedFileURL)
    }

    private func makeDownloader() -> ModelDownloader {
        ModelDownloader(sessionFactory: { delegate in
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        })
    }

    private func makeEntry(sha: String, size: Int64) -> ModelCatalogEntry {
        ModelCatalogEntry(
            id: "fixture-\(UUID().uuidString)",
            displayName: "Fixture",
            family: .other,
            parameterCount: "0.5B",
            quantization: "Q4_K_M",
            downloadURL: URL(string: "https://example.com/test.gguf")!,
            sha256: sha,
            sizeBytes: size,
            ramMinGB: 1,
            promptTemplate: .chatML
        )
    }

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: "localmind-dl-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

private final class ProgressRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: ModelDownloader.Progress?
    var value: ModelDownloader.Progress? { lock.withLock { _value } }
    func record(_ progress: ModelDownloader.Progress) {
        lock.withLock { _value = progress }
    }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: 0))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
