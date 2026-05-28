import Foundation

public enum EmbeddedRuntimeCompatibility: Sendable, Equatable {
    case supported
    case unsupported(reason: String)

    public var isSupported: Bool {
        if case .supported = self { return true }
        return false
    }

    public var reason: String? {
        if case .unsupported(let reason) = self { return reason }
        return nil
    }
}

public struct EmbeddedRuntimeCompatibilityChecker: Sendable {
    public init() {}

    public func compatibility(for entry: ModelCatalogEntry) -> EmbeddedRuntimeCompatibility {
        compatibility(forModelName: entry.id)
    }

    public func compatibility(forModelURL url: URL) -> EmbeddedRuntimeCompatibility {
        compatibility(forModelName: url.lastPathComponent)
    }

    private func compatibility(forModelName name: String) -> EmbeddedRuntimeCompatibility {
        let normalized = name.lowercased()

        if normalized.contains("qwen3") {
            return .unsupported(reason: "This LocalMind build ships SwiftLlama 0.4.0 on llama.cpp b5046, which cannot load Qwen 3 GGUF models yet. Choose a Qwen 2.5, Llama 3.2, Phi 4 Mini, Gemma 3, or Ministral entry instead.")
        }

        return .supported
    }
}