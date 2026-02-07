import AppKit

/// Tracks the last 9 unique clipboard entries.
/// Polls the system pasteboard for changes and maintains a chronological history.
class ClipboardHistory: ObservableObject {
    static let shared = ClipboardHistory()

    /// Maximum preview length for display in the UI
    static let maxPreviewLength = 60

    /// Each history entry stores the full text and a timestamp
    struct Entry: Identifiable {
        let id = UUID()
        let text: String
        let timestamp: Date

        /// Truncated preview for UI display, single-line with "..." if needed
        var preview: String {
            let singleLine = text
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .trimmingCharacters(in: .whitespaces)
            if singleLine.count > ClipboardHistory.maxPreviewLength {
                return String(singleLine.prefix(ClipboardHistory.maxPreviewLength)) + "..."
            }
            return singleLine
        }
    }

    @Published private(set) var entries: [Entry] = []

    private let maxEntries = 9
    private var lastChangeCount: Int = 0
    private var pollTimer: Timer?

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startPolling()
    }

    /// Start polling the pasteboard for changes every 0.5s
    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    /// Check if the pasteboard has new content
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let text = pasteboard.string(forType: .string) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        addEntry(trimmed)
    }

    /// Manually record a clipboard entry (called from ClipboardService after copy)
    func recordCurrentClipboard() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount
        guard let text = pasteboard.string(forType: .string) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        addEntry(trimmed)
    }

    private func addEntry(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Remove duplicate if same text already exists
            self.entries.removeAll { $0.text == text }

            // Insert at the beginning (most recent first)
            let entry = Entry(text: text, timestamp: Date())
            self.entries.insert(entry, at: 0)

            // Trim to max entries
            if self.entries.count > self.maxEntries {
                self.entries = Array(self.entries.prefix(self.maxEntries))
            }
        }
    }

    /// Copy a history entry back to the clipboard
    func copyEntry(_ entry: Entry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.text, forType: .string)
        lastChangeCount = pasteboard.changeCount  // Don't re-record this as a new entry
    }
}
