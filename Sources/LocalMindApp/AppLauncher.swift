import Foundation
import LocalMindCore
import LocalMindStorage

@MainActor
@Observable
final class AppLauncher {
    enum Phase {
        case loading
        case ready(viewModel: ChatViewModel, modelURL: URL)
        case modelMissing(directory: URL)
        case failed(message: String)
    }

    var phase: Phase = .loading

    func start() {
        Task { await loadModelAndPrepareViewModel() }
    }

    private func loadModelAndPrepareViewModel() async {
        let resolver = ModelResolver()
        let modelURL: URL
        do {
            modelURL = try resolver.resolveModelURL()
        } catch ModelResolverError.noModelFound(let searched) {
            let directory = searched.first ?? URL(fileURLWithPath: NSHomeDirectory())
            phase = .modelMissing(directory: directory)
            return
        } catch {
            phase = .failed(message: "Model lookup failed: \(error.localizedDescription)")
            return
        }

        let backend = LlamaInferenceBackend()
        do {
            try await backend.loadModel(at: modelURL)
        } catch {
            phase = .failed(message: "Could not load model at \(modelURL.path): \(error.localizedDescription)")
            return
        }

        let template = template(for: modelURL)
        let engine = LiveChatEngine(backend: backend, template: template)
        let store: ChatStore
        let persistedMessages: [PersistedMessage]
        do {
            store = try ChatStore()
            persistedMessages = try store.load()
        } catch {
            phase = .failed(message: "Storage init failed: \(error.localizedDescription)")
            return
        }

        let viewModel = ChatViewModel(
            engine: engine,
            store: store,
            initialMessages: ChatViewModel.mappedMessages(from: persistedMessages)
        )
        phase = .ready(viewModel: viewModel, modelURL: modelURL)
    }

    private func template(for url: URL) -> PromptTemplate {
        let name = url.lastPathComponent.lowercased()
        if name.contains("llama-3") || name.contains("llama3") { return .llama3 }
        if name.contains("mistral") { return .mistral }
        if name.contains("phi") { return .phi }
        if name.contains("gemma") { return .gemma }
        return .chatML
    }
}
