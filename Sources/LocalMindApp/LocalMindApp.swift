import AppKit
import LocalMindCore
import LocalMindLicense
import LocalMindRAG
import LocalMindStorage
import SwiftUI

@main
struct LocalMindApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }
}
