import LocalMindCore
import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    let modelURL: URL
    let onManageModels: () -> Void
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messagesScrollView
            Divider()
            inputBar
        }
        .frame(minWidth: 600, minHeight: 420)
        .background(.background)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Text("LocalMind")
                    .font(.headline)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: onManageModels) {
                    Label("Models", systemImage: "square.stack.3d.up")
                }
                .help("Switch to another downloaded model or download a new one")
                .disabled(viewModel.isGenerating)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    viewModel.clear()
                } label: {
                    Label("New chat", systemImage: "square.and.pencil")
                }
                .disabled(viewModel.messages.isEmpty || viewModel.isGenerating)
            }
        }
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    if let error = viewModel.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.last?.content) {
                if let id = viewModel.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Start a conversation")
                .font(.title3)
                .bold()
            Text("Type a message below. Inference runs locally on your Mac.")
                .foregroundStyle(.secondary)
            Text("Current model: \(modelURL.lastPathComponent)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 24)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message LocalMind…", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...6)
                .focused($inputFocused)
                .onSubmit(sendIfPossible)
                .onAppear { inputFocused = true }

            if viewModel.isGenerating {
                Button(role: .destructive) {
                    viewModel.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .labelStyle(.iconOnly)
                }
                .keyboardShortcut(".", modifiers: .command)
            } else {
                Button(action: sendIfPossible) {
                    Label("Send", systemImage: "paperplane.fill")
                        .labelStyle(.iconOnly)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!viewModel.canSend)
            }
        }
        .padding(12)
    }

    private func sendIfPossible() {
        guard viewModel.canSend else { return }
        viewModel.send()
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            roleBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(roleLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(message.content.isEmpty ? "…" : message.content)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(bubbleColor, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var roleBadge: some View {
        Image(systemName: message.role == .assistant ? "sparkles" : "person.fill")
            .frame(width: 22, height: 22)
            .foregroundStyle(.secondary)
    }

    private var roleLabel: String {
        switch message.role {
        case .system: return "System"
        case .user: return "You"
        case .assistant: return "LocalMind"
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .assistant: return .secondary.opacity(0.12)
        case .user: return .accentColor.opacity(0.18)
        case .system: return .secondary.opacity(0.06)
        }
    }
}
