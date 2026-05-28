import XCTest
@testable import LocalMindCore

final class LlamaInferenceBackendTests: XCTestCase {
    func testKindIsLlamaCPP() {
        let backend = LlamaInferenceBackend()
        XCTAssertEqual(backend.kind, .llamaCPP)
    }

    func testGenerateFailsWhenModelNotLoaded() async {
        let backend = LlamaInferenceBackend()
        let request = InferenceRequest(userMessage: "Hello")
        let stream = backend.generate(request)
        do {
            for try await _ in stream {
                XCTFail("Stream should not produce tokens without a loaded model")
            }
            XCTFail("Stream should throw modelNotLoaded")
        } catch let error as LlamaInferenceBackendError {
            XCTAssertEqual(error, .modelNotLoaded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLoadModelThrowsForMissingFile() async {
        let backend = LlamaInferenceBackend()
        let missing = URL(fileURLWithPath: "/tmp/localmind-nonexistent-\(UUID().uuidString).gguf")
        do {
            try await backend.loadModel(at: missing)
            XCTFail("Expected loadModel to throw for a missing path")
        } catch {
            // SwiftLlama wraps llama.cpp's load failure; any error is acceptable here.
        }
    }

    // End-to-end smoke test against a real GGUF model. Skipped unless
    // LOCALMIND_MODEL_PATH points at an existing file. Use a tiny model
    // (Qwen 2.5 0.5B Q4 K_M) to keep wall time under a few seconds.
    func testEndToEndSmokeIfModelAvailable() async throws {
        guard let modelPath = ProcessInfo.processInfo.environment["LOCALMIND_MODEL_PATH"],
              FileManager.default.fileExists(atPath: modelPath)
        else {
            throw XCTSkip("Set LOCALMIND_MODEL_PATH to a GGUF file to run this test")
        }

        let backend = LlamaInferenceBackend()
        try await backend.loadModel(at: URL(fileURLWithPath: modelPath))

        let request = InferenceRequest(
            systemPrompt: "You are concise.",
            userMessage: "Say only the word: ok",
            template: .chatML,
            maxTokens: 16
        )

        var output = ""
        for try await chunk in backend.generate(request) {
            output += chunk
            if output.count > 64 { break }
        }
        XCTAssertFalse(output.isEmpty, "Expected at least one streamed token")
    }
}
