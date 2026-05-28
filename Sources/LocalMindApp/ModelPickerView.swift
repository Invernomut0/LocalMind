import LocalMindCore
import SwiftUI

struct ModelPickerView: View {
    let entries: [ModelCatalogEntry]
    let modelsDir: URL
    let hostMemory: HostMemory
    let warningMessage: String?
    let currentModelURL: URL?
    let onCancel: (() -> Void)?
    let onSelect: (ModelCatalogEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let warningMessage {
                warningBanner(warningMessage)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(entries) { entry in
                        ModelEntryRow(
                            entry: entry,
                            hostMemory: hostMemory,
                            modelsDir: modelsDir,
                            currentModelURL: currentModelURL
                        ) {
                            onSelect(entry)
                        }
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
            Text("This Mac has \(hostMemory.formattedCapacity) unified memory. Recommendations below are based on the model's practical minimum RAM.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("All models are verified by SHA-256 after download.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let onCancel {
                Button("Back", action: onCancel)
                    .controlSize(.small)
            }
            Button("Open folder") {
                NSWorkspace.shared.activateFileViewerSelecting([modelsDir])
            }
            .controlSize(.small)
        }
    }

    private func warningBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct ModelEntryRow: View {
    let entry: ModelCatalogEntry
    let hostMemory: HostMemory
    let modelsDir: URL
    let currentModelURL: URL?
    let onDownload: () -> Void

    var body: some View {
        let recommendation = entry.ramRecommendation(for: hostMemory)
        let installedURL = entry.installedModelURL(in: modelsDir)
        let isInstalled = installedURL != nil
        let isCurrent = currentModelURL.map(entry.matches(localModelURL:)) ?? false
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
                if isInstalled {
                    Text(isCurrent ? "Installed locally · current model" : "Installed locally")
                        .font(.caption)
                        .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                }
                recommendationLabel(recommendation)
            }
            Spacer()
            actionButton(for: recommendation, isInstalled: isInstalled, isCurrent: isCurrent)
        }
        .padding(10)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            badge(for: recommendation)
        }
        .opacity(recommendation.isRecommended ? 1 : 0.84)
    }

    private var sizeLabel: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: entry.sizeBytes)) · needs ≥\(entry.ramMinGB) GB RAM"
    }

    @ViewBuilder
    private func recommendationLabel(_ recommendation: ModelRAMRecommendation) -> some View {
        switch recommendation.suitability {
        case .recommended:
            Text("Recommended on this Mac")
                .font(.caption)
                .foregroundStyle(.green)
        case .constrained(let missingGB):
            Text("May feel slow on this Mac — practical target is about \(missingGB) GB more RAM")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private func badge(for recommendation: ModelRAMRecommendation) -> some View {
        switch recommendation.suitability {
        case .recommended:
            Text("Good fit")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green.opacity(0.16), in: Capsule())
                .foregroundStyle(.green)
                .padding(8)
        case .constrained:
            Text("Heavy")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.16), in: Capsule())
                .foregroundStyle(.orange)
                .padding(8)
        }
    }

    @ViewBuilder
    private func actionButton(for recommendation: ModelRAMRecommendation, isInstalled: Bool, isCurrent: Bool) -> some View {
        if isCurrent {
            Button {
            } label: {
                Label("Current", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.bordered)
            .disabled(true)
        } else {
            switch recommendation.suitability {
            case .recommended:
                Button(action: onDownload) {
                    Label(isInstalled ? "Use now" : "Download", systemImage: isInstalled ? "play.circle" : "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
            case .constrained:
                Button(action: onDownload) {
                    Label(isInstalled ? "Use now" : "Download", systemImage: isInstalled ? "play.circle" : "arrow.down.circle")
                }
                .buttonStyle(.bordered)
            }
        }
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
