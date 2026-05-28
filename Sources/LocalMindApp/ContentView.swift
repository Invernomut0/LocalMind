import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("LocalMind")
                .font(.largeTitle)
                .bold()
            Text("Sprint 0 skeleton — chat UI lands in Sprint 1.")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 480, minHeight: 320)
        .padding()
    }
}
