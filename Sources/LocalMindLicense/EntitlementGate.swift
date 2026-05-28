import Foundation

public enum Entitlement: String, Sendable, CaseIterable {
    case appleNotes
    case multiFolder
    case mxbaiEmbedLarge
    case shortcutsIntents
    case menuBarApp
    case cloudBYOK
    case icloudSync
}

public protocol EntitlementGate: Sendable {
    func canUse(_ entitlement: Entitlement) async -> Bool
}
