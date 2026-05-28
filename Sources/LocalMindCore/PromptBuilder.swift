import Foundation

public struct PromptBuilder: Sendable {
    public init() {}

    public func render(history: [ChatMessage], systemPrompt: String?) -> String {
        var parts: [String] = []
        if let systemPrompt, !systemPrompt.isEmpty {
            parts.append("<|system|>\n\(systemPrompt)")
        }
        for message in history {
            parts.append("<|\(message.role.rawValue)|>\n\(message.content)")
        }
        parts.append("<|assistant|>\n")
        return parts.joined(separator: "\n")
    }
}
