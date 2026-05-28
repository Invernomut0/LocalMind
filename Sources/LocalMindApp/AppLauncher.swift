import Foundation
import LocalMindCore
import LocalMindStorage

@MainActor
@Observable
final class AppLauncher {
    enum Phase {
        case loading
        case ready(viewModel: ChatViewModel, modelURL: URL)
        case catalogPicker(entries: [ModelCatalogEntry], modelsDir: URL)
        case downloading(entry: ModelCatalogEntry, progress: ModelDownloader.Progress)
        case modelMissing(directory: URL)
        case failed(message: String)
    }

    var phase: Phase = .loading

    private let catalog: any ModelCatalog
    private let downloader: ModelDownloader
    private var downloadTask: Task<Void, Never>?

    init(
        catalog: any ModelCatalog = FallbackModelCatalog(
            primary: RemoteModelCatalog(),
            fallback: BundledModelCatalog()
        ),
        downloader: ModelDownloader = ModelDownloader()
    ) {
        self.catalog = catalog
        self.downloader = downloader
    }

    func start() {
        Task { await initialResolve() }
    }

    func selectAndDownload(_ entry: ModelCatalogEntry, modelsDir: URL) {
        downloadTask?.cancel()
        phase = .downloading(entry: entry, progress: .init(bytesDownloaded: 0, totalBytes: entry.sizeBytes))
        downloadTask = Task { await runDownload(entry: entry, modelsDir: modelsDir) }
    }

    func cancelDownload(modelsDir: URL) {
        downloadTask?.cancel()
        downloadTask = nil
        Task { await reloadCatalog(modelsDir: modelsDir) }
    }

    private func initialResolve() async {
        let resolver = ModelResolver()
        switch result(of: { try resolver.resolveModelURL() }) {
        case .success(let url):
            await loadAndPrepare(modelURL: url)
        case .failure(let error):
            await transitionFromResolveError(error)
        }
    }

    private func transitionFromResolveError(_ error: Error) async {
        if case ModelResolverError.noModelFound(let searched) = error {
            let dir = searched.first ?? (try? ModelResolver().defaultModelsDirectory()) ?? URL(fileURLWithPath: NSHomeDirectory())
            await reloadCatalog(modelsDir: dir)
            return
        }
        phase = .failed(message: "Model lookup failed: \(error.localizedDescription)")
    }

    private func reloadCatalog(modelsDir: URL) async {
        do {
            let document = try await catalog.load()
            phase = .catalogPicker(entries: document.models, modelsDir: modelsDir)
        } catch {
            phase = .modelMissing(directory: modelsDir)
        }
    }

    private func runDownload(entry: ModelCatalogEntry, modelsDir: URL) async {
        do {
            let destination = try await downloader.download(entry: entry, destinationDir: modelsDir) { [weak self] update in
                Task { @MainActor [weak self] in
                    guard let self,
                          case .downloading(let current, _) = self.phase,
                          current.id == entry.id
                    else { return }
                    self.phase = .downloading(entry: current, progress: update)
                }
            }
            await loadAndPrepare(modelURL: destination)
        } catch is CancellationError {
            await reloadCatalog(modelsDir: modelsDir)
        } catch {
            phase = .failed(message: "Download failed: \(error.localizedDescription)")
        }
    }

    private func loadAndPrepare(modelURL: URL) async {
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
        let persisted: [PersistedMessage]
        do {
            store = try ChatStore()
            persisted = try store.load()
        } catch {
            phase = .failed(message: "Storage init failed: \(error.localizedDescription)")
            return
        }

        let viewModel = ChatViewModel(
            engine: engine,
            store: store,
            initialMessages: ChatViewModel.mappedMessages(from: persisted)
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

    private func result<T>(of work: () throws -> T) -> Result<T, Error> {
        Result { try work() }
    }
}
