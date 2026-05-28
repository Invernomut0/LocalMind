import AppKit
import LocalMindCore
import SwiftUI

struct ContentView: View {
    @State private var launcher = AppLauncher()

    var body: some View {
        Group {
            switch launcher.phase {
            case .loading:
                LoadingView()
            case .ready(let viewModel, let modelURL):
                ChatView(viewModel: viewModel)
                    .navigationTitle(modelURL.lastPathComponent)
            case .catalogPicker(let entries, let modelsDir, let hostMemory):
                ModelPickerView(entries: entries, modelsDir: modelsDir, hostMemory: hostMemory) { entry in
                    launcher.selectAndDownload(entry, modelsDir: modelsDir)
                }
            case .downloading(let entry, let progress):
                DownloadingView(entry: entry, progress: progress) {
                    // Fallback: derive modelsDir from the entry's expected install path.
                    let dir = (try? ModelResolver().defaultModelsDirectory()) ?? URL(fileURLWithPath: NSHomeDirectory())
                    launcher.cancelDownload(modelsDir: dir)
                }
            case .modelMissing(let directory):
                ModelMissingView(modelsDirectory: directory)
            case .failed(let message):
                FailureView(message: message)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .task { launcher.start() }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading local model…")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

private struct ModelMissingView: View {
    let modelsDirectory: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("No GGUF model found", systemImage: "tray.full")
                .font(.title3)
                .bold()

            Text("LocalMind looks for a `.gguf` file in:")
            Text(modelsDirectory.path)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

            Text("Drop a Qwen 2.5 0.5B Q4 (or similar small model) GGUF into that folder, then relaunch the app. You can also set the `LOCALMIND_MODEL_PATH` environment variable to an explicit path.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Open folder in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([modelsDirectory])
                }
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: 560)
    }
}

private struct FailureView: View {
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("LocalMind could not start", systemImage: "exclamationmark.triangle")
                .font(.title3)
                .bold()
            Text(message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(24)
        .frame(maxWidth: 560)
    }
}

