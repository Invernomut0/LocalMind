import XCTest
@testable import LocalMindCore

final class ChecksumVerifierTests: XCTestCase {
    func testHashMatchesKnownFixture() async throws {
        // "hello world" -> b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
        let url = try writeTemp(content: "hello world")
        defer { try? FileManager.default.removeItem(at: url) }
        let verifier = ChecksumVerifier()
        let hash = try await verifier.sha256(of: url)
        XCTAssertEqual(hash, "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9")
    }

    func testVerifySucceedsOnMatch() async throws {
        let url = try writeTemp(content: "data")
        defer { try? FileManager.default.removeItem(at: url) }
        let verifier = ChecksumVerifier()
        let hash = try await verifier.sha256(of: url)
        try await verifier.verify(url, expectedSHA256: hash)
    }

    func testVerifyThrowsOnMismatch() async throws {
        let url = try writeTemp(content: "data")
        defer { try? FileManager.default.removeItem(at: url) }
        let verifier = ChecksumVerifier()
        do {
            try await verifier.verify(url, expectedSHA256: String(repeating: "0", count: 64))
            XCTFail("Expected mismatch")
        } catch ChecksumError.mismatch {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFileUnreadableThrows() async {
        let missing = URL(fileURLWithPath: "/tmp/localmind-checksum-missing-\(UUID().uuidString)")
        let verifier = ChecksumVerifier()
        do {
            _ = try await verifier.sha256(of: missing)
            XCTFail("Expected fileUnreadable")
        } catch ChecksumError.fileUnreadable {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHashesLargeFileCorrectly() async throws {
        // Stream a 200 KB random file (>3 internal 64 KiB buffers) and verify
        // we can re-hash to the same digest.
        var bytes = Data(count: 200_000)
        bytes.withUnsafeMutableBytes { ptr in
            _ = SecRandomCopyBytes(kSecRandomDefault, ptr.count, ptr.baseAddress!)
        }
        let url = FileManager.default.temporaryDirectory.appending(path: "localmind-large-\(UUID().uuidString).bin")
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let verifier = ChecksumVerifier()
        let firstHash = try await verifier.sha256(of: url)
        let secondHash = try await verifier.sha256(of: url)
        XCTAssertEqual(firstHash, secondHash)
        XCTAssertEqual(firstHash.count, 64)
    }

    private func writeTemp(content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "localmind-cv-\(UUID().uuidString).txt")
        try content.data(using: .utf8)!.write(to: url)
        return url
    }
}

import Security
