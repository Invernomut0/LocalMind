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
        _ = name
        return .supported
    }
}