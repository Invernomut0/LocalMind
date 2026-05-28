import XCTest
@testable import LocalMindCore

final class LiveChatEngineTests: XCTestCase {
    func testReplyPassesThroughBackendTokens() async throws {
        let backend = StubBackend(tokens: ["Hello", ", ", "world"])
        let engine = LiveChatEngine(backend: backend)
        let stream = engine.reply(to: [.init(role: .user, content: "Hi")])

        var collected = ""
        for try await chunk in stream {
            collected += chunk
        }
        XCTAssertEqual(collected, "Hello, world")
        XCTAssertEqual(backend.lastRequest?.userMessage, "Hi")
        XCTAssertEqual(backend.lastRequest?.template, .chatML)
    }

    func testReplyForwardsBackendError() async {
        let backend = StubBackend(error: TestError.boom)
        let engine = LiveChatEngine(backend: backend)
        let stream = engine.reply(to: [.init(role: .user, content: "Hi")])
        do {
            for try await _ in stream {}
            XCTFail("Expected backend error")
        } catch is TestError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReplyEmitsBuilderErrorWhenNoUserMessage() async {
        let backend = StubBackend(tokens: [])
        let engine = LiveChatEngine(backend: backend)
        let stream = engine.reply(to: [.init(role: .system, content: "system only")])
        do {
            for try await _ in stream {}
            XCTFail("Expected PromptBuilderError")
        } catch let error as PromptBuilderError {
            XCTAssertEqual(error, .missingUserMessage)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDefaultSystemPromptIsUsedWhenHistoryHasNone() async throws {
        let backend = StubBackend(tokens: ["ok"])
        let engine = LiveChatEngine(backend: backend, defaultSystemPrompt: "Be brief.")
        for try await _ in engine.reply(to: [.init(role: .user, content: "Hi")]) {}
        XCTAssertEqual(backend.lastRequest?.systemPrompt, "Be brief.")
    }
}

private enum TestError: Error { case boom }

private final class StubBackend: InferenceBackend, @unchecked Sendable {
    let kind: InferenceBackendKind = .llamaCPP
    var lastRequest: InferenceRequest?
    private let tokens: [String]
    private let error: Error?

    init(tokens: [String] = [], error: Error? = nil) {
        self.tokens = tokens
        self.error = error
    }

    func loadModel(at url: URL) async throws {}

    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<String, Error> {
        lastRequest = request
        return AsyncThrowingStream { continuation in
            if let error {
                continuation.finish(throwing: error)
                return
            }
            for token in tokens {
                continuation.yield(token)
            }
            continuation.finish()
        }
    }
}
