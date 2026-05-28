import XCTest
@testable import LocalMindCore

final class PromptBuilderTests: XCTestCase {
    func testRenderIncludesSystemPromptAndHistory() {
        let builder = PromptBuilder()
        let history: [ChatMessage] = [
            .init(role: .user, content: "Hello"),
            .init(role: .assistant, content: "Hi there")
        ]
        let rendered = builder.render(history: history, systemPrompt: "Be concise.")
        XCTAssertTrue(rendered.contains("<|system|>\nBe concise."))
        XCTAssertTrue(rendered.contains("<|user|>\nHello"))
        XCTAssertTrue(rendered.contains("<|assistant|>\nHi there"))
        XCTAssertTrue(rendered.hasSuffix("<|assistant|>\n"))
    }

    func testRenderWithoutSystemPrompt() {
        let builder = PromptBuilder()
        let rendered = builder.render(history: [.init(role: .user, content: "Ping")], systemPrompt: nil)
        XCTAssertFalse(rendered.contains("<|system|>"))
        XCTAssertTrue(rendered.contains("<|user|>\nPing"))
    }
}
