import Foundation

public enum ModelResolverError: Error, Equatable {
    case noModelFound(searchedAt: [URL])
    case envPathInvalid(String)
}

public struct ModelResolver {
    public static let envVarName = "LOCALMIND_MODEL_PATH"
    public static let defaultDirectoryName = "LocalMind/Models"

    private let fileManager: FileManager
    private let environment: [String: String]

    public init(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.environment = environment
    }

    public func resolveModelURL() throws -> URL {
        if let envPath = environment[Self.envVarName], !envPath.isEmpty {
            let url = URL(fileURLWithPath: (envPath as NSString).expandingTildeInPath)
            guard fileManager.fileExists(atPath: url.path) else {
                throw ModelResolverError.envPathInvalid(envPath)
            }
            return url
        }

        let directory = try defaultModelsDirectory()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let candidates = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        if let gguf = candidates.first(where: { $0.pathExtension.lowercased() == "gguf" }) {
            return gguf
        }
        throw ModelResolverError.noModelFound(searchedAt: [directory])
    }

    public func defaultModelsDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupport.appending(path: Self.defaultDirectoryName)
    }
}
