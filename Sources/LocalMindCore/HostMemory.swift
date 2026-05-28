import Foundation

public struct HostMemory: Sendable, Equatable {
    public let physicalMemoryBytes: UInt64

    public init(physicalMemoryBytes: UInt64) {
        self.physicalMemoryBytes = physicalMemoryBytes
    }

    public var physicalMemoryGB: Int {
        max(1, Int(physicalMemoryBytes / 1_073_741_824))
    }

    public var formattedCapacity: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(physicalMemoryBytes))
    }
}

public struct HostMemoryDetector: Sendable {
    private let physicalMemoryBytesProvider: @Sendable () -> UInt64

    public init(
        physicalMemoryBytesProvider: @escaping @Sendable () -> UInt64 = {
            ProcessInfo.processInfo.physicalMemory
        }
    ) {
        self.physicalMemoryBytesProvider = physicalMemoryBytesProvider
    }

    public func current() -> HostMemory {
        HostMemory(physicalMemoryBytes: physicalMemoryBytesProvider())
    }
}

public struct ModelRAMRecommendation: Sendable, Equatable {
    public enum Suitability: Sendable, Equatable {
        case recommended
        case constrained(missingGB: Int)
    }

    public let hostMemory: HostMemory
    public let minimumRAMGB: Int
    public let suitability: Suitability

    public var isRecommended: Bool {
        if case .recommended = suitability { return true }
        return false
    }
}

public extension ModelCatalogEntry {
    func ramRecommendation(for hostMemory: HostMemory) -> ModelRAMRecommendation {
        let missingGB = max(0, ramMinGB - hostMemory.physicalMemoryGB)
        let suitability: ModelRAMRecommendation.Suitability = missingGB == 0
            ? .recommended
            : .constrained(missingGB: missingGB)

        return ModelRAMRecommendation(
            hostMemory: hostMemory,
            minimumRAMGB: ramMinGB,
            suitability: suitability
        )
    }
}