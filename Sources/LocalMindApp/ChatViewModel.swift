import Foundation
import LocalMindCore
import LocalMindStorage

@MainActor
@Observable
final class ChatViewModel {
    var messages: [ChatMessage]
    var isGenerating: Bool = false
    var input: String = ""
    var lastError: String?

    private let engine: any ChatEngine
    private let store: ChatStore
    private var generationTask: Task<Void, Never>?
    private var streamingAssistantID: UUID?

    init(engine: any ChatEngine, store: ChatStore, initialMessages: [ChatMessage] = []) {
        self.engine = engine
        self.store = store
        self.messages = initialMessages
    }

    var canSend: Bool {
        !isGenerating && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        let placeholder = ChatMessage(role: .assistant, content: "")
        messages.append(userMessage)
        messages.append(placeholder)
        streamingAssistantID = placeholder.id
        input = ""
        isGenerating = true
        lastError = nil
        persist()

        let history = messages.dropLast()
        generationTask = Task { [weak self] in
            await self?.stream(history: Array(history), placeholderID: placeholder.id)
        }
    }

    func stop() {
        generationTask?.cancel()
    }

    func clear() {
        stop()
        messages.removeAll()
        streamingAssistantID = nil
        lastError = nil
        try? store.clear()
    }

    private func stream(history: [ChatMessage], placeholderID: UUID) async {
        do {
            for try await chunk in engine.reply(to: history) {
                if Task.isCancelled { break }
                appendChunk(chunk, to: placeholderID)
            }
        } catch {
            lastError = error.localizedDescription
        }
        await MainActor.run {
            self.isGenerating = false
            self.streamingAssistantID = nil
            self.persist()
        }
    }

    private func appendChunk(_ chunk: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let existing = messages[index]
        messages[index] = ChatMessage(
            id: existing.id,
            role: existing.role,
            content: existing.content + chunk,
            createdAt: existing.createdAt
        )
    }

    private func persist() {
        let persisted = messages.map { msg in
            PersistedMessage(
                id: msg.id,
                role: PersistedMessage.Role(rawValue: msg.role.rawValue) ?? .user,
                content: msg.content,
                createdAt: msg.createdAt
            )
        }
        do {
            try store.save(persisted)
        } catch {
            lastError = "Persistence failed: \(error.localizedDescription)"
        }
    }
}

extension ChatViewModel {
    static func mappedMessages(from persisted: [PersistedMessage]) -> [ChatMessage] {
        persisted.map { msg in
            ChatMessage(
                id: msg.id,
                role: ChatMessage.Role(rawValue: msg.role.rawValue) ?? .user,
                content: msg.content,
                createdAt: msg.createdAt
            )
        }
    }
}
