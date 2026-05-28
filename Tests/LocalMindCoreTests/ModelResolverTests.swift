import XCTest
@testable import LocalMindCore

final class ModelResolverTests: XCTestCase {
    func testEnvironmentPathTakesPrecedenceWhenFileExists() throws {
        let tmp = FileManager.default.temporaryDirectory.appending(path: "resolver-\(UUID().uuidString).gguf")
        try Data([0xAA]).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let resolver = ModelResolver(environment: [ModelResolver.envVarName: tmp.path])
        let resolved = try resolver.resolveModelURL()
        XCTAssertEqual(resolved.standardizedFileURL, tmp.standardizedFileURL)
    }

    func testEnvironmentPathInvalidThrows() {
        let resolver = ModelResolver(environment: [ModelResolver.envVarName: "/tmp/definitely-missing-\(UUID().uuidString).gguf"])
        XCTAssertThrowsError(try resolver.resolveModelURL()) { error in
            guard case ModelResolverError.envPathInvalid = error else {
                XCTFail("Expected envPathInvalid, got \(error)")
                return
            }
        }
    }

}
