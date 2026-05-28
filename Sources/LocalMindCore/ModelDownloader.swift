import Foundation

public enum ModelDownloaderError: Error, Equatable {
    case httpStatus(Int)
    case missingTotalBytes
    case ioFailed(String)
    case alreadyExistsWithDifferentChecksum
}

public final class ModelDownloader: @unchecked Sendable {
    public struct Progress: Sendable, Equatable {
        public let bytesDownloaded: Int64
        public let totalBytes: Int64

        public init(bytesDownloaded: Int64, totalBytes: Int64) {
            self.bytesDownloaded = bytesDownloaded
            self.totalBytes = totalBytes
        }

        public var fraction: Double {
            totalBytes > 0 ? Double(bytesDownloaded) / Double(totalBytes) : 0
        }
    }

    private let verifier: ChecksumVerifier
    private let fileManager: FileManager
    private let sessionFactory: @Sendable (URLSessionDelegate) -> URLSession

    public init(
        verifier: ChecksumVerifier = ChecksumVerifier(),
        fileManager: FileManager = .default,
        sessionFactory: @escaping @Sendable (URLSessionDelegate) -> URLSession = { delegate in
            URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        }
    ) {
        self.verifier = verifier
        self.fileManager = fileManager
        self.sessionFactory = sessionFactory
    }

    /// Downloads `entry` into `destinationDir`, returning the final file URL.
    ///
    /// If a file already exists at `destinationDir/<entry.id>.gguf` and matches
    /// `entry.sha256`, the download is skipped and the existing URL is returned
    /// immediately. If the file exists but doesn't match the catalog checksum,
    /// it is deleted and re-downloaded.
    public func download(
        entry: ModelCatalogEntry,
        destinationDir: URL,
        progress: @escaping @Sendable (Progress) -> Void
    ) async throws -> URL {
        try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        let destination = destinationDir.appending(path: "\(entry.id).gguf")

        if fileManager.fileExists(atPath: destination.path) {
            do {
                try await verifier.verify(destination, expectedSHA256: entry.sha256)
                progress(Progress(bytesDownloaded: entry.sizeBytes, totalBytes: entry.sizeBytes))
                return destination
            } catch {
                try? fileManager.removeItem(at: destination)
            }
        }

        let coordinator = DownloadCoordinator(progress: progress, expectedBytes: entry.sizeBytes)
        let session = sessionFactory(coordinator)
        defer { session.finishTasksAndInvalidate() }

        let tempURL = try await coordinator.run(url: entry.downloadURL, session: session)
        defer { try? fileManager.removeItem(at: tempURL) }

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        do {
            try fileManager.moveItem(at: tempURL, to: destination)
        } catch {
            throw ModelDownloaderError.ioFailed(error.localizedDescription)
        }

        do {
            try await verifier.verify(destination, expectedSHA256: entry.sha256)
        } catch {
            try? fileManager.removeItem(at: destination)
            throw error
        }
        return destination
    }
}

private final class DownloadCoordinator: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let progress: @Sendable (ModelDownloader.Progress) -> Void
    private let expectedBytes: Int64
    private let lock = NSLock()
    private var continuation: CheckedContinuation<URL, Error>?

    init(
        progress: @escaping @Sendable (ModelDownloader.Progress) -> Void,
        expectedBytes: Int64
    ) {
        self.progress = progress
        self.expectedBytes = expectedBytes
    }

    func run(url: URL, session: URLSession) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            lock.withLock { continuation = cont }
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        if let response = downloadTask.response as? HTTPURLResponse,
           !(200..<300).contains(response.statusCode) {
            resume(.failure(ModelDownloaderError.httpStatus(response.statusCode)))
            return
        }

        // The system deletes the file at `location` once this callback returns,
        // so we have to copy it out synchronously.
        let tempCopy = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "localmind-dl-\(UUID().uuidString).bin")
        do {
            try FileManager.default.moveItem(at: location, to: tempCopy)
            resume(.success(tempCopy))
        } catch {
            resume(.failure(ModelDownloaderError.ioFailed(error.localizedDescription)))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            resume(.failure(error))
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : expectedBytes
        progress(ModelDownloader.Progress(
            bytesDownloaded: totalBytesWritten,
            totalBytes: total
        ))
    }

    private func resume(_ result: Result<URL, Error>) {
        let pending: CheckedContinuation<URL, Error>? = lock.withLock {
            let c = continuation
            continuation = nil
            return c
        }
        pending?.resume(with: result)
    }
}
