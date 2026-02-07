import SwiftUI

struct ActionListWindow: View {
    let text: String
    let detection: ContentResult
    let actions: [ActionItem]
    @ObservedObject var selectionState: SelectionState
    let onDismiss: () -> Void
    let onExecute: (ActionItem) -> Void

    @State private var showResult: Bool = false
    @State private var resultTitle: String = ""
    @State private var resultGenerator: (() async throws -> String)?
    @State private var pendingResultText: String = ""
    @State private var showSettings: Bool = false
    @State private var showHistory: Bool = false
    @State private var showCustomPrompt: Bool = false
    @StateObject private var historySelectionState = SelectionState()
    @StateObject private var customPromptState = CustomPromptState()

    /// Corner radius matching Spotlight's rounded appearance
    private let cornerRadius: CGFloat = 20

    /// Which screen is currently active — used for keyboard routing
    private var activeScreen: Screen {
        if showSettings { return .settings }
        if showHistory { return .history }
        if showResult { return .result }
        if showCustomPrompt { return .customPrompt }
        return .actions
    }

    private enum Screen {
        case actions, result, settings, history, customPrompt
    }

    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectBackground()

            if showCustomPrompt {
                CustomPromptView(
                    clipboardText: text,
                    state: customPromptState
                )
            } else if showSettings {
                settingsContent
            } else if showHistory {
                ClipboardHistoryView(
                    selectionState: historySelectionState,
                    onSelect: { entry in
                        ClipboardHistory.shared.copyEntry(entry)
                        copyAndDismissWithToast()
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showHistory = false
                        }
                    }
                )
            } else if showResult, let generator = resultGenerator {
                ResultView(
                    title: resultTitle,
                    onBack: { goBackToActions() },
                    onResult: { text in pendingResultText = text },
                    generator: generator
                )
            } else {
                actionListContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.caiDivider.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiExecuteAction"))) { notification in
            if let actionId = notification.userInfo?["actionId"] as? String,
               let action = actions.first(where: { $0.id == actionId }) {
                executeAction(action)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiEscPressed"))) { _ in
            handleEsc()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiShowClipboardHistory"))) { _ in
            handleShowHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiCmdNumber"))) { notification in
            if let number = notification.userInfo?["number"] as? Int {
                handleCmdNumber(number)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiArrowUp"))) { _ in
            handleArrowUp()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiArrowDown"))) { _ in
            handleArrowDown()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CaiEnterPressed"))) { _ in
            handleEnter()
        }
    }

    // MARK: - Keyboard Routing

    private func handleEsc() {
        if showCustomPrompt {
            if customPromptState.phase == .result {
                withAnimation(.easeInOut(duration: 0.15)) {
                    customPromptState.phase = .input
                }
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showCustomPrompt = false
                    customPromptState.reset()
                }
            }
        } else if showSettings {
            withAnimation(.easeInOut(duration: 0.15)) {
                showSettings = false
            }
        } else if showHistory {
            withAnimation(.easeInOut(duration: 0.15)) {
                showHistory = false
            }
        } else if showResult {
            goBackToActions()
        } else {
            onDismiss()
        }
    }

    private func handleShowHistory() {
        guard activeScreen == .actions else { return }
        historySelectionState.selectedIndex = 0
        withAnimation(.easeInOut(duration: 0.15)) {
            showHistory = true
        }
    }

    private func handleCmdNumber(_ number: Int) {
        switch activeScreen {
        case .actions:
            if let action = actions.first(where: { $0.shortcut == number }) {
                if let index = actions.firstIndex(where: { $0.id == action.id }) {
                    selectionState.selectedIndex = index
                }
                executeAction(action)
            }
        case .history:
            let historyIndex = number - 1
            let entries = ClipboardHistory.shared.entries
            guard historyIndex >= 0, historyIndex < entries.count else { return }
            historySelectionState.selectedIndex = historyIndex
            ClipboardHistory.shared.copyEntry(entries[historyIndex])
            copyAndDismissWithToast()
        default:
            break
        }
    }

    private func handleArrowUp() {
        switch activeScreen {
        case .actions:
            let current = selectionState.selectedIndex
            selectionState.selectedIndex = current > 0 ? current - 1 : actions.count - 1
        case .history:
            let entries = ClipboardHistory.shared.entries
            guard !entries.isEmpty else { return }
            let current = historySelectionState.selectedIndex
            historySelectionState.selectedIndex = current > 0 ? current - 1 : entries.count - 1
        default:
            break
        }
    }

    private func handleArrowDown() {
        switch activeScreen {
        case .actions:
            let current = selectionState.selectedIndex
            selectionState.selectedIndex = current < actions.count - 1 ? current + 1 : 0
        case .history:
            let entries = ClipboardHistory.shared.entries
            guard !entries.isEmpty else { return }
            let current = historySelectionState.selectedIndex
            historySelectionState.selectedIndex = current < entries.count - 1 ? current + 1 : 0
        default:
            break
        }
    }

    private func handleEnter() {
        switch activeScreen {
        case .actions:
            let index = selectionState.selectedIndex
            guard index < actions.count else { return }
            executeAction(actions[index])
        case .history:
            let entries = ClipboardHistory.shared.entries
            let index = historySelectionState.selectedIndex
            guard index < entries.count else { return }
            ClipboardHistory.shared.copyEntry(entries[index])
            copyAndDismissWithToast()
        case .result:
            if !pendingResultText.isEmpty {
                SystemActions.copyToClipboard(pendingResultText)
            }
            copyAndDismissWithToast()
        case .customPrompt:
            if customPromptState.phase == .result {
                if !customPromptState.resultText.isEmpty {
                    SystemActions.copyToClipboard(customPromptState.resultText)
                }
                copyAndDismissWithToast()
            }
        default:
            break
        }
    }

    private func copyAndDismissWithToast() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CaiShowToast"),
            object: nil,
            userInfo: ["message": "Copied to Clipboard"]
        )
        onDismiss()
    }

    private func goBackToActions() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showResult = false
            resultGenerator = nil
            resultTitle = ""
            pendingResultText = ""
        }
    }

    // MARK: - Action List Content

    private var actionListContent: some View {
        VStack(spacing: 0) {
            headerView

            Divider()
                .background(Color.caiDivider)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                            ActionRow(action: action, isSelected: index == selectionState.selectedIndex)
                                .id(index)
                                .onTapGesture {
                                    selectionState.selectedIndex = index
                                    executeAction(actions[index])
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

            Divider()
                .background(Color.caiDivider)

            mainFooterView
        }
    }

    // MARK: - Settings Content (inline)

    private var settingsContent: some View {
        VStack(spacing: 0) {
            SettingsView()
            Divider()
                .background(Color.caiDivider)
            HStack(spacing: 16) {
                keyboardHint(key: "Esc", label: "Back")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {
            Image(systemName: iconForType(detection.type))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.caiPrimary)

            VStack(alignment: .leading, spacing: 1) {
                Text(labelForType(detection.type))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.caiTextSecondary)

                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.caiTextPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Footer (Main Action View)

    private var mainFooterView: some View {
        HStack(spacing: 12) {
            keyboardHint(key: "↑↓", label: "Navigate")
            keyboardHint(key: "↵", label: "Select")
            keyboardHint(key: "Esc", label: "Close")
            keyboardHint(key: "⌘0", label: "History")

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showSettings = true
                }
            }) {
                CaiLogo(color: .caiTextSecondary.opacity(0.35))
                    .frame(height: 12)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Settings")
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Keyboard Hint Helper

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

    // MARK: - Helpers

    private func iconForType(_ type: ContentType) -> String {
        switch type {
        case .url: return "link"
        case .json: return "curlybraces"
        case .address: return "mappin.and.ellipse"
        case .meeting: return "calendar"
        case .word: return "textformat.abc"
        case .shortText: return "text.alignleft"
        case .longText: return "doc.text"
        }
    }

    private func labelForType(_ type: ContentType) -> String {
        switch type {
        case .url: return "URL detected"
        case .json: return "JSON detected"
        case .address: return "Address detected"
        case .meeting: return "Date/Meeting detected"
        case .word: return "Word detected"
        case .shortText: return "Text detected"
        case .longText: return "Long text detected"
        }
    }

    // MARK: - Actions

    private func executeAction(_ action: ActionItem) {
        switch action.type {
        case .jsonPrettyPrint(let json):
            showResultView(title: "Pretty Print JSON") {
                return Self.prettyPrintJSON(json)
            }

        case .llmAction(let llmAction):
            let title = llmActionTitle(llmAction)
            let clipboardText = self.text
            print("🔍 executeAction: self.text = \(clipboardText.prefix(80))...")
            showResultView(title: title) {
                let llm = LLMService.shared
                switch llmAction {
                case .summarize:
                    return try await llm.summarize(clipboardText)
                case .translate(let lang):
                    return try await llm.translate(clipboardText, to: lang)
                case .define:
                    return try await llm.define(clipboardText)
                case .explain:
                    return try await llm.explain(clipboardText)
                case .custom(let instruction):
                    return try await llm.customAction(clipboardText, instruction: instruction)
                }
            }

        case .customPrompt:
            customPromptState.reset()
            withAnimation(.easeInOut(duration: 0.15)) {
                showCustomPrompt = true
            }

        default:
            // System actions (openURL, openMaps, search, createCalendar)
            onExecute(action)
        }
    }

    private func showResultView(title: String, generator: @escaping () async throws -> String) {
        resultTitle = title
        resultGenerator = generator
        withAnimation(.easeInOut(duration: 0.15)) {
            showResult = true
        }
    }

    private func llmActionTitle(_ action: LLMAction) -> String {
        switch action {
        case .summarize: return "Summary"
        case .translate(let lang): return "Translation (\(lang))"
        case .define: return "Definition"
        case .explain: return "Explanation"
        case .custom(let prompt): return prompt
        }
    }

    // MARK: - Static helpers

    private static func prettyPrintJSON(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: pretty, encoding: .utf8) else {
            return json
        }
        return result
    }
}
