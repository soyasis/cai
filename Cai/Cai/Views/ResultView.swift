import SwiftUI

/// Shows the result of an action (LLM response, pretty-printed JSON, etc.)
/// inside the floating window, replacing the action list.
/// The result is automatically copied to the clipboard.
/// ESC returns to the action list (handled by parent), not dismiss.
struct ResultView: View {
    let title: String
    let onBack: () -> Void

    @State private var result: String = ""
    @State private var isLoading: Bool = true
    @State private var error: String?
    @State private var copied: Bool = false

    /// Async generator that produces the result string.
    let generator: () async throws -> String

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.caiPrimary)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.caiTextPrimary)

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

            // Content area
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

            Divider()
                .background(Color.caiDivider)

            // Footer
            HStack {
                keyboardHint(key: "Esc", label: "Back")
                Spacer()
                if !isLoading && error == nil {
                    keyboardHint(key: "⌘V", label: "Paste result")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .task {
            do {
                let output = try await generator()
                withAnimation(.easeOut(duration: 0.2)) {
                    result = output
                    isLoading = false
                }
                // Auto-copy to clipboard
                copyToClipboard(output)
                withAnimation(.spring(response: 0.3)) {
                    copied = true
                }
                // Reset copied indicator after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    copied = false
                }
            } catch {
                withAnimation {
                    self.error = error.localizedDescription
                    isLoading = false
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

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
