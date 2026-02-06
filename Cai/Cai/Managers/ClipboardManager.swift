import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private var pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: Timer?
    private let maxItems = 100

    init() {
        self.changeCount = pasteboard.changeCount
        startMonitoring()
        loadFromUserDefaults()
    }

    func startMonitoring() {
        // Poll clipboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        guard pasteboard.changeCount != changeCount else { return }

        changeCount = pasteboard.changeCount

        guard let copiedString = pasteboard.string(forType: .string),
              !copiedString.isEmpty else { return }

        // Don't add duplicates of the most recent item
        if let lastItem = items.first, lastItem.content == copiedString {
            return
        }

        let type = ClipboardItem.detectType(from: copiedString)
        let newItem = ClipboardItem(content: copiedString, type: type)

        items.insert(newItem, at: 0)

        // Keep only the most recent items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        saveToUserDefaults()
        print("📋 New clipboard item captured: \(copiedString.prefix(50))...")
    }

    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        changeCount = pasteboard.changeCount

        // Move item to the top
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let item = items.remove(at: index)
            items.insert(item, at: 0)
        }

        print("📋 Copied to clipboard: \(item.content.prefix(50))...")
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveToUserDefaults()
    }

    func clearAll() {
        items.removeAll()
        saveToUserDefaults()
    }

    // MARK: - Persistence

    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "clipboardHistory")
        }
    }

    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            print("📋 Loaded \(items.count) clipboard items from storage")
        }
    }

    deinit {
        stopMonitoring()
    }
}
