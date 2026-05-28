import XCTest
@testable import LocalMindCore

final class PromptBuilderTests: XCTestCase {
    func testBuildsRequestFromUserMessage() throws {
        let builder = PromptBuilder()
        let history: [ChatMessage] = [
            .init(role: .system, content: "Be concise."),
            .init(role: .user, content: "Hello")
        ]
        let request = try builder.makeRequest(history: history)
        XCTAssertEqual(request.systemPrompt, "Be concise.")
        XCTAssertEqual(request.userMessage, "Hello")
        XCTAssertTrue(request.history.isEmpty)
        XCTAssertEqual(request.template, .chatML)
    }

    func testHistoryIsPairedAndTrailingUserBecomesCurrentMessage() throws {
        let builder = PromptBuilder()
        let history: [ChatMessage] = [
            .init(role: .user, content: "First question"),
            .init(role: .assistant, content: "First answer"),
            .init(role: .user, content: "Follow-up")
        ]
        let request = try builder.makeRequest(history: history, systemPrompt: "Override")
        XCTAssertEqual(request.systemPrompt, "Override")
        XCTAssertEqual(request.userMessage, "Follow-up")
        XCTAssertEqual(request.history, [ChatTurn(user: "First question", assistant: "First answer")])
    }

    func testExplicitSystemPromptOverridesSystemMessage() throws {
        let builder = PromptBuilder()
        let history: [ChatMessage] = [
            .init(role: .system, content: "From message"),
            .init(role: .user, content: "Hi")
        ]
        let request = try builder.makeRequest(history: history, systemPrompt: "From argument")
        XCTAssertEqual(request.systemPrompt, "From argument")
    }

    func testMissingUserMessageThrows() {
        let builder = PromptBuilder()
        XCTAssertThrowsError(try builder.makeRequest(history: [])) { error in
            XCTAssertEqual(error as? PromptBuilderError, .missingUserMessage)
        }
    }

    func testTemplateIsPassedThrough() throws {
        let builder = PromptBuilder()
        let request = try builder.makeRequest(
            history: [.init(role: .user, content: "Hi")],
            template: .llama3
        )
        XCTAssertEqual(request.template, .llama3)
    }
}
