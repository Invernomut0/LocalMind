import Foundation

public struct Prompt {
    public enum `Type` {
        case chatML
        case alpaca
        case llama
        case llama3
        case mistral
        case phi
        case gemma
    }

    public let type: `Type`
    public let systemPrompt: String
    public let userMessage: String
    public let history: [Chat]

    public init(type: `Type`,
                systemPrompt: String = "",
                userMessage: String,
                history: [Chat] = []) {
        self.type = type
        self.systemPrompt = systemPrompt
        self.userMessage = userMessage
        self.history = history
    }

    var prompt: String {
        switch type {
        case .llama: encodeLlamaPrompt()
        case .llama3: encodeLlama3Prompt()
        case .alpaca: encodeAlpacaPrompt()
        case .chatML: encodeChatMLPrompt()
        case .mistral: encodeMistralPrompt()
        case .phi: encodePhiPrompt()
        case .gemma: encodeGemmaPrompt()
        }
    }

    private func encodeLlamaPrompt() -> String {
        """
        [INST]<<SYS>>
        \(systemPrompt)
        <</SYS>>
        \(history.suffix(Configuration.historySize).map { $0.llamaPrompt }.joined())
        [/INST]
        [INST]
        \(userMessage)
        [/INST]
        """
    }

    private func encodeLlama3Prompt() -> String {
        let prompt = """
        <|start_header_id|>system<|end_header_id|>\(systemPrompt)<|eot_id|>
        
        \(history.suffix(Configuration.historySize).map { $0.llama3Prompt }.joined())
        
        <|start_header_id|>user<|end_header_id|>\(userMessage)<|eot_id|>
        <|start_header_id|>assistant<|end_header_id|>
        """
      return prompt
    }

    private func encodeAlpacaPrompt() -> String {
        """
        Below is an instruction that describes a task.
        Write a response that appropriately completes the request.
        \(userMessage)
        """
    }

    private func encodeChatMLPrompt() -> String {
        // Rebuilt from the upstream SwiftLlama 0.4.0 encoder which emitted
        // literal `"<|im_start|>user"` (stray quote characters) and dropped
        // the system prompt entirely. The result confused Qwen 2.5 chat
        // models into echoing the malformed scaffold. See ADR-0005.
        var parts: [String] = []
        if !systemPrompt.isEmpty {
            parts.append("<|im_start|>system\n\(systemPrompt)<|im_end|>")
        }
        for chat in history.suffix(Configuration.historySize) {
            parts.append("<|im_start|>user\n\(chat.user)<|im_end|>")
            parts.append("<|im_start|>assistant\n\(chat.bot)<|im_end|>")
        }
        parts.append("<|im_start|>user\n\(userMessage)<|im_end|>")
        parts.append("<|im_start|>assistant\n")
        return parts.joined(separator: "\n")
    }

    private func encodeMistralPrompt() -> String {
        """
        <s>
        \(history.suffix(Configuration.historySize).map { $0.mistralPrompt }.joined())
        </s>
        [INST] \(userMessage) [/INST]
        """
    }

    private func encodePhiPrompt() -> String {
        """
        \(systemPrompt)
        \(history.suffix(Configuration.historySize).map { $0.phiPrompt }.joined())
        <|user|>
        \(userMessage)
        <|end|>
        <|assistant|>
        """
    }

    private func encodeGemmaPrompt() -> String {
        """
        <start_of_turn>system
        \(systemPrompt)
        <end_of_turn>
        \(history.suffix(Configuration.historySize).map { $0.gemmaPrompt }.joined())
        <start_of_turn>user
        \(userMessage)
        <end_of_turn>
        <start_of_turn>model
        """
    }
}
