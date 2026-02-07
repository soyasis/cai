import SwiftUI

/// Submenu showing the last 9 clipboard entries, triggered by Cmd+0.
/// Same visual design as the action list. Each entry has a Cmd+N shortcut
/// to quickly copy it. Selecting an entry copies it to clipboard and closes the window.
struct ClipboardHistoryView: View {
    @ObservedObject var history = ClipboardHistory.shared
    @ObservedObject var selectionState: SelectionState
    let onSelect: (ClipboardHistory.Entry) -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.caiPrimary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Clipboard History")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.caiTextPrimary)

                    Text("Last \(history.entries.count) copied items")
                        .font(.system(size: 11))
                        .foregroundColor(.caiTextSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.caiDivider)

            // History list
            if history.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 28))
                        .foregroundColor(.caiTextSecondary.opacity(0.4))
                    Text("No clipboard history yet")
                        .font(.system(size: 13))
                        .foregroundColor(.caiTextSecondary)
                    Text("Copy some text to get started")
                        .font(.system(size: 11))
                        .foregroundColor(.caiTextSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(history.entries.enumerated()), id: \.element.id) { index, entry in
                                historyRow(entry: entry, index: index, isSelected: index == selectionState.selectedIndex)
                                    .id(index)
                                    .onTapGesture {
                                        selectionState.selectedIndex = index
                                        onSelect(entry)
                                    }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                    }
                    .onChange(of: selectionState.selectedIndex) { newValue in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }

            Divider()
                .background(Color.caiDivider)

            // Footer
            HStack(spacing: 12) {
                KeyboardHint(key: "↑↓", label: "Navigate")
                KeyboardHint(key: "↵", label: "Copy")
                KeyboardHint(key: "Esc", label: "Back")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - History Row

    private func historyRow(entry: ClipboardHistory.Entry, index: Int, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.caiPrimary.opacity(0.15) : Color.caiSurface.opacity(0.6))
                    .frame(width: 28, height: 28)

                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .caiPrimary : .caiTextSecondary)
            }

            // Preview text
            Text(entry.preview)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.caiTextPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Shortcut badge (⌘1 through ⌘9)
            if index < 9 {
                HStack(spacing: 2) {
                    Text("\u{2318}")
                        .font(.system(size: 10, weight: .medium))
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(.caiTextSecondary.opacity(0.7))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.caiSurface.opacity(0.5))
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.caiSelection : Color.clear)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Clipboard entry \(index + 1): \(entry.preview)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

}
