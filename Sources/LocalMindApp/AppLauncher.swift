import Foundation
import LocalMindCore
import LocalMindStorage

@MainActor
@Observable
final class AppLauncher {
    private struct SuspendedReadyState {
        let viewModel: ChatViewModel
        let modelURL: URL
    }

    enum Phase {
        case loading
        case ready(viewModel: ChatViewModel, modelURL: URL)
        case catalogPicker(entries: [ModelCatalogEntry], modelsDir: URL, hostMemory: HostMemory, warningMessage: String?, currentModelURL: URL?, canCancel: Bool)
        case downloading(entry: ModelCatalogEntry, progress: ModelDownloader.Progress)
        case modelMissing(directory: URL)
        case failed(message: String)
    }

    var phase: Phase = .loading

    private let catalog: any ModelCatalog
    private let downloader: ModelDownloader
    private let hostMemoryDetector: HostMemoryDetector
    private let compatibilityChecker: EmbeddedRuntimeCompatibilityChecker
    private var cachedCatalogDocument: ModelCatalogDocument?
    private var downloadTask: Task<Void, Never>?
    private var suspendedReadyState: SuspendedReadyState?

    init(
        catalog: any ModelCatalog = FallbackModelCatalog(
            primary: RemoteModelCatalog(),
            fallback: BundledModelCatalog()
        ),
        downloader: ModelDownloader = ModelDownloader(),
        hostMemoryDetector: HostMemoryDetector = HostMemoryDetector(),
        compatibilityChecker: EmbeddedRuntimeCompatibilityChecker = EmbeddedRuntimeCompatibilityChecker()
    ) {
        self.catalog = catalog
        self.downloader = downloader
        self.hostMemoryDetector = hostMemoryDetector
        self.compatibilityChecker = compatibilityChecker
    }

    func start() {
        Task { await initialResolve() }
    }

    func selectAndDownload(_ entry: ModelCatalogEntry, modelsDir: URL) {
        if let installedURL = entry.installedModelURL(in: modelsDir) {
            suspendedReadyState = nil
            phase = .loading
            Task { await loadAndPrepare(modelURL: installedURL, preferredTemplate: entry.promptTemplate) }
            return
        }

        downloadTask?.cancel()
        phase = .downloading(entry: entry, progress: .init(bytesDownloaded: 0, totalBytes: entry.sizeBytes))
        downloadTask = Task { await runDownload(entry: entry, modelsDir: modelsDir) }
    }

    func showModelCatalog() {
        guard case .ready(let viewModel, let modelURL) = phase else { return }
        suspendedReadyState = SuspendedReadyState(viewModel: viewModel, modelURL: modelURL)
        Task {
            await reloadCatalog(
                modelsDir: modelURL.deletingLastPathComponent(),
                currentModelURL: modelURL,
                canCancel: true
            )
        }
    }

    func dismissModelCatalog() {
        guard let suspendedReadyState else { return }
        phase = .ready(viewModel: suspendedReadyState.viewModel, modelURL: suspendedReadyState.modelURL)
        self.suspendedReadyState = nil
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
            if let warningMessage = compatibilityChecker.compatibility(forModelURL: url).reason {
                await reloadCatalog(modelsDir: url.deletingLastPathComponent(), warningMessage: warningMessage)
                return
            }
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

    private func reloadCatalog(
        modelsDir: URL,
        warningMessage: String? = nil,
        currentModelURL: URL? = nil,
        canCancel: Bool? = nil
    ) async {
        do {
            let document = try await loadCatalogDocument()
            let resolvedCurrentModelURL = currentModelURL ?? suspendedReadyState?.modelURL
            phase = .catalogPicker(
                entries: document.models.filter { compatibilityChecker.compatibility(for: $0).isSupported },
                modelsDir: modelsDir,
                hostMemory: hostMemoryDetector.current(),
                warningMessage: warningMessage,
                currentModelURL: resolvedCurrentModelURL,
                canCancel: canCancel ?? (suspendedReadyState != nil)
            )
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
            await loadAndPrepare(modelURL: destination, preferredTemplate: entry.promptTemplate)
        } catch is CancellationError {
            await reloadCatalog(modelsDir: modelsDir)
        } catch {
            phase = .failed(message: "Download failed: \(error.localizedDescription)")
        }
    }

    private func loadAndPrepare(modelURL: URL, preferredTemplate: PromptTemplate? = nil) async {
        let backend = LlamaInferenceBackend()
        do {
            try await backend.loadModel(at: modelURL)
        } catch {
            phase = .failed(message: "Could not load model at \(modelURL.path): \(error.localizedDescription)")
            return
        }

        let template = await resolveTemplate(for: modelURL, preferredTemplate: preferredTemplate)
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
        suspendedReadyState = nil
        phase = .ready(viewModel: viewModel, modelURL: modelURL)
    }

    private func resolveTemplate(for modelURL: URL, preferredTemplate: PromptTemplate?) async -> PromptTemplate {
        if let preferredTemplate {
            return preferredTemplate
        }

        if let document = try? await loadCatalogDocument(),
           let entry = document.entry(matchingModelURL: modelURL) {
            return entry.promptTemplate
        }

        return template(for: modelURL)
    }

    private func loadCatalogDocument() async throws -> ModelCatalogDocument {
        if let cachedCatalogDocument {
            return cachedCatalogDocument
        }
        let document = try await catalog.load()
        cachedCatalogDocument = document
        return document
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
