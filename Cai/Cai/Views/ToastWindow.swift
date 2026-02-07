import SwiftUI

/// Pill-shaped toast notification view — dark background with white text.
/// Mimics Raycast's "Copied to Clipboard" toast.
struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}
