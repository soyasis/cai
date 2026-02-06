import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var searchText = ""

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        }
        return clipboardManager.items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clipboard")
                    .font(.title2)
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                if !clipboardManager.items.isEmpty {
                    Button(action: {
                        clipboardManager.clearAll()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear all")
                }
            }
            .padding()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Clipboard items list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history yet" : "No results found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Copy something to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(item: item, clipboardManager: clipboardManager)
                                .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let clipboardManager: ClipboardManager
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.type.icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .lineLimit(3)
                    .font(.system(.body, design: .default))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(item.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if isHovered {
                        Button(action: {
                            clipboardManager.deleteItem(item)
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                }
            }
        }
        .padding(12)
        .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            clipboardManager.copyToClipboard(item)
        }
    }
}

#Preview {
    ContentView(clipboardManager: ClipboardManager())
}
