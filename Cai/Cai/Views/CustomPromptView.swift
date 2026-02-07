import SwiftUI

/// Shared state for CustomPromptView so the parent can query its phase
/// and route keyboard events correctly.
class CustomPromptState: ObservableObject {
    @Published var phase: CustomPromptPhase = .input

    func reset() {
        phase = .input
    }
}

enum CustomPromptPhase {
    case input, result
}

/// Inline view for typing a custom prompt to send to the local LLM.
/// Two phases: (1) text input, (2) result display.
/// Keyboard events are routed by the parent (ActionListWindow).
struct CustomPromptView: View {
    let clipboardText: String
    @ObservedObject var state: CustomPromptState

    @State private var prompt: String = ""
    @State private var result: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var copied: Bool = false

    @FocusState private var isPromptFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.caiPrimary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Custom Action")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.caiTextPrimary)

                    Text(clipboardText)
                        .font(.system(size: 11))
                        .foregroundColor(.caiTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                if copied {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Copied")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.green)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.caiDivider)

            // Content
            if state.phase == .input {
                inputContent
            } else {
                resultContent
            }

            Divider()
                .background(Color.caiDivider)

            // Footer
            HStack(spacing: 12) {
                keyboardHint(key: "Esc", label: "Back")
                if state.phase == .input {
                    keyboardHint(key: "↵", label: "Submit")
                } else if !isLoading && error == nil {
                    keyboardHint(key: "⌘V", label: "Paste result")
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onChange(of: state.phase) { newPhase in
            WindowController.passThrough = (newPhase == .input)
        }
    }

    // MARK: - Input Phase

    private var inputContent: some View {
        VStack(spacing: 12) {
            Text("What would you like to do with this content?")
                .font(.system(size: 12))
                .foregroundColor(.caiTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("e.g. Rewrite formally, Extract key points, Convert to bullet list...", text: $prompt)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.caiTextPrimary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.caiSurface.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.caiDivider.opacity(0.5), lineWidth: 0.5)
                )
                .focused($isPromptFocused)
                .onSubmit {
                    submitPrompt()
                }
        }
        .padding(16)
        .onAppear {
            WindowController.passThrough = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPromptFocused = true
            }
        }
        .onDisappear {
            WindowController.passThrough = false
        }
    }

    // MARK: - Result Phase

    private var resultContent: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.system(size: 12))
                        .foregroundColor(.caiTextSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            } else if let error = error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.caiTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            } else {
                Text(result)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.caiTextPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
        .frame(maxHeight: 240)
    }

    // MARK: - Private

    private func submitPrompt() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            state.phase = .result
            isLoading = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let preview = String(clipboardText.prefix(50))
            let output = "[LLM Integration Pending]\n\nPrompt: \(trimmed)\nContent: \"\(preview)...\""

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    result = output
                    isLoading = false
                }
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(output, forType: .string)
                withAnimation(.spring(response: 0.3)) {
                    copied = true
                }
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation {
                    copied = false
                }
            }
        }
    }

    private func keyboardHint(key: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.caiSurface.opacity(0.5))
                )
            Text(label)
                .font(.system(size: 11))
        }
        .foregroundColor(.caiTextSecondary.opacity(0.6))
    }
}
