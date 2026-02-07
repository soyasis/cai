import SwiftUI

extension Color {
    static let caiBackground = Color(nsColor: .windowBackgroundColor).opacity(0.95)
    static let caiSurface = Color(nsColor: .controlBackgroundColor)
    static let caiPrimary = Color(red: 0.39, green: 0.40, blue: 0.95)  // Indigo
    static let caiTextPrimary = Color(nsColor: .labelColor)
    static let caiTextSecondary = Color(nsColor: .secondaryLabelColor)
    static let caiSelection = Color(nsColor: .selectedContentBackgroundColor).opacity(0.15)
    static let caiDivider = Color(nsColor: .separatorColor)
}
