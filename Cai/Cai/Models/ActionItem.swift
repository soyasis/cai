import Foundation

// MARK: - Action Models

struct ActionItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String  // SF Symbol name or emoji
    let shortcut: Int
    let type: ActionType
}

enum ActionType {
    case openURL(URL)
    case openMaps(String)
    case createCalendar(title: String, date: Date, location: String?)
    case search(String)
    case llmAction(LLMAction)
    case copyText(String)
    case jsonPrettyPrint(String)
    case customPrompt
    case translateCustom
}

enum LLMAction {
    case summarize
    case translate(String)
    case define
    case explain
    case custom(String)
}

// MARK: - Action Provider

/// Generates context-aware actions based on the detected content type.
class ActionProvider {

    static let shared = ActionProvider()

    private init() {}

    func actions(for text: String, detection: ContentResult) -> [ActionItem] {
        var items: [ActionItem] = []
        var shortcut = 1

        // Always offer Custom Action first
        items.append(ActionItem(
            id: "custom_prompt",
            title: "Custom Action",
            subtitle: "Ask AI anything about this content",
            icon: "bolt.fill",
            shortcut: shortcut,
            type: .customPrompt
        ))
        shortcut += 1

        // Content-specific actions
        switch detection.type {
        case .url:
            if let urlString = detection.entities.url, let url = URL(string: urlString) {
                items.append(ActionItem(
                    id: "open_url",
                    title: "Open URL",
                    subtitle: urlString,
                    icon: "safari",
                    shortcut: shortcut,
                    type: .openURL(url)
                ))
                shortcut += 1
            }
            items.append(ActionItem(
                id: "summarize_url",
                title: "Summarize Page",
                subtitle: "Get a summary of this webpage",
                icon: "doc.text.magnifyingglass",
                shortcut: shortcut,
                type: .llmAction(.summarize)
            ))
            shortcut += 1

        case .json:
            items.append(ActionItem(
                id: "pretty_print",
                title: "Pretty Print JSON",
                subtitle: "Format and copy to clipboard",
                icon: "curlybraces",
                shortcut: shortcut,
                type: .jsonPrettyPrint(text)
            ))
            shortcut += 1
            items.append(ActionItem(
                id: "explain_json",
                title: "Explain Structure",
                subtitle: "Describe this JSON data",
                icon: "lightbulb",
                shortcut: shortcut,
                type: .llmAction(.explain)
            ))
            shortcut += 1

        case .address:
            let address = detection.entities.address ?? text
            items.append(ActionItem(
                id: "open_maps",
                title: "Open in Maps",
                subtitle: address,
                icon: "map",
                shortcut: shortcut,
                type: .openMaps(address)
            ))
            shortcut += 1

        case .meeting:
            let dateText = detection.entities.dateText ?? "event"
            items.append(ActionItem(
                id: "create_event",
                title: "Create Calendar Event",
                subtitle: dateText,
                icon: "calendar.badge.plus",
                shortcut: shortcut,
                type: .createCalendar(
                    title: text,
                    date: detection.entities.date ?? Date(),
                    location: detection.entities.location
                )
            ))
            shortcut += 1

        case .word:
            items.append(ActionItem(
                id: "define_word",
                title: "Define Word",
                subtitle: "Look up definition",
                icon: "character.book.closed",
                shortcut: shortcut,
                type: .llmAction(.define)
            ))
            shortcut += 1

        case .shortText, .longText:
            break  // Generic actions below cover these
        }

        // Generic actions available for all content types
        items.append(ActionItem(
            id: "explain",
            title: "Explain",
            subtitle: "Get an explanation of this content",
            icon: "lightbulb",
            shortcut: shortcut,
            type: .llmAction(.explain)
        ))
        shortcut += 1

        let targetLanguage = CaiSettings.shared.translationLanguage
        items.append(ActionItem(
            id: "translate",
            title: "Translate to \(targetLanguage)",
            subtitle: nil,
            icon: "globe",
            shortcut: shortcut,
            type: .llmAction(.translate(targetLanguage))
        ))
        shortcut += 1

        if detection.type == .longText || detection.type == .shortText {
            items.append(ActionItem(
                id: "summarize",
                title: "Summarize",
                subtitle: "Create a concise summary",
                icon: "text.redaction",
                shortcut: shortcut,
                type: .llmAction(.summarize)
            ))
            shortcut += 1
        }

        items.append(ActionItem(
            id: "search_web",
            title: "Search Web",
            subtitle: nil,
            icon: "magnifyingglass",
            shortcut: shortcut,
            type: .search(text)
        ))
        shortcut += 1

        return items
    }
}
