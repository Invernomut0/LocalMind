import Foundation

public struct PromptBuilder: Sendable {
    public init() {}

    public func makeRequest(
        history: [ChatMessage],
        systemPrompt: String? = nil,
        template: PromptTemplate = .chatML
    ) throws -> InferenceRequest {
        let messages = history.filter { $0.role != .system }
        guard let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) else {
            throw PromptBuilderError.missingUserMessage
        }

        let priorMessages = Array(messages[..<lastUserIndex])
        let turns = pairs(in: priorMessages)
        let resolvedSystemPrompt = systemPrompt ?? history.first(where: { $0.role == .system })?.content

        return InferenceRequest(
            systemPrompt: resolvedSystemPrompt,
            userMessage: messages[lastUserIndex].content,
            history: turns,
            template: template
        )
    }

    private func pairs(in messages: [ChatMessage]) -> [ChatTurn] {
        var result: [ChatTurn] = []
        var pendingUser: String?
        for message in messages {
            switch message.role {
            case .user:
                pendingUser = message.content
            case .assistant:
                if let user = pendingUser {
                    result.append(ChatTurn(user: user, assistant: message.content))
                    pendingUser = nil
                }
            case .system:
                continue
            }
        }
        return result
    }
}

public enum PromptBuilderError: Error, Equatable {
    case missingUserMessage
}
