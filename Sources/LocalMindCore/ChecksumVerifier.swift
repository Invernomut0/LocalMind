import CryptoKit
import Foundation

public enum ChecksumError: Error, Equatable {
    case mismatch(expected: String, actual: String)
    case fileUnreadable(String)
}

public struct ChecksumVerifier: Sendable {
    public static let bufferSize = 1 << 16 // 64 KiB

    public init() {}

    public func sha256(of fileURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let stream = InputStream(url: fileURL) else {
            throw ChecksumError.fileUnreadable(fileURL.path)
        }
        return try await Task.detached(priority: .utility) {
            stream.open()
            defer { stream.close() }
            if stream.streamStatus == .error {
                throw ChecksumError.fileUnreadable(fileURL.path)
            }
            var hasher = SHA256()
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Self.bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: Self.bufferSize)
                if read < 0 {
                    throw ChecksumError.fileUnreadable(fileURL.path)
                }
                if read == 0 { break }
                hasher.update(bufferPointer: UnsafeRawBufferPointer(start: buffer, count: read))
            }
            let digest = hasher.finalize()
            return digest.map { String(format: "%02x", $0) }.joined()
        }.value
    }

    public func verify(_ fileURL: URL, expectedSHA256 expected: String) async throws {
        let actual = try await sha256(of: fileURL)
        if actual.lowercased() != expected.lowercased() {
            throw ChecksumError.mismatch(expected: expected.lowercased(), actual: actual)
        }
    }
}
