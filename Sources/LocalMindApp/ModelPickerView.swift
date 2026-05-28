import LocalMindCore
import SwiftUI

struct ModelPickerView: View {
    let entries: [ModelCatalogEntry]
    let modelsDir: URL
    let onSelect: (ModelCatalogEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(entries) { entry in
                        ModelEntryRow(entry: entry) { onSelect(entry) }
                    }
                }
            }
            footer
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 360)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Choose a model")
                .font(.title2)
                .bold()
            Text("Models download into \(modelsDir.path) and stay on your Mac.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("All models are verified by SHA-256 after download.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Open folder") {
                NSWorkspace.shared.activateFileViewerSelecting([modelsDir])
            }
            .controlSize(.small)
        }
    }
}

private struct ModelEntryRow: View {
    let entry: ModelCatalogEntry
    let onDownload: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName).font(.body).bold()
                    Text(entry.parameterCount).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.secondary)
                    Text(entry.quantization).foregroundStyle(.secondary)
                }
                if let notes = entry.notes {
                    Text(notes).font(.caption).foregroundStyle(.secondary)
                }
                Text(sizeLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: onDownload) {
                Label("Download", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var sizeLabel: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: entry.sizeBytes)) · needs ≥\(entry.ramMinGB) GB RAM"
    }
}

struct DownloadingView: View {
    let entry: ModelCatalogEntry
    let progress: ModelDownloader.Progress
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Downloading \(entry.displayName)")
                .font(.title3)
                .bold()
            if progress.totalBytes > 0 {
                ProgressView(value: progress.fraction)
                    .progressViewStyle(.linear)
            } else {
                ProgressView()
            }
            HStack {
                Text(progressLabel)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel", role: .destructive, action: onCancel)
                    .controlSize(.small)
            }
        }
        .padding(24)
        .frame(maxWidth: 520)
    }

    private var progressLabel: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        let downloaded = formatter.string(fromByteCount: progress.bytesDownloaded)
        let total = formatter.string(fromByteCount: max(progress.totalBytes, entry.sizeBytes))
        let pct = Int((progress.fraction * 100).rounded())
        return "\(downloaded) / \(total) (\(pct)%)"
    }
}
