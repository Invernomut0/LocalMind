import Foundation

public enum LicenseStatus: Sendable, Equatable {
    case unlicensed
    case valid(LicenseRecord)
    case grace(LicenseRecord, daysRemaining: Int)
    case expired(LicenseRecord)
    case tampered
}

public protocol LicenseValidator: Sendable {
    func validate(_ record: LicenseRecord, now: Date) async -> LicenseStatus
}
