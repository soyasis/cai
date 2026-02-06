import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ClipboardType

    init(content: String, type: ClipboardType = .text) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
    }

    enum ClipboardType: String, Codable {
        case text
        case code
        case url

        var icon: String {
            switch self {
            case .text: return "doc.text"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .url: return "link"
            }
        }
    }

    // Detect type from content
    static func detectType(from content: String) -> ClipboardType {
        // Simple URL detection
        if content.starts(with: "http://") || content.starts(with: "https://") {
            return .url
        }

        // Simple code detection (contains common code patterns)
        let codePatterns = ["func ", "class ", "def ", "import ", "const ", "let ", "var ", "{", "}", "()", "//", "/*"]
        if codePatterns.contains(where: { content.contains($0) }) {
            return .code
        }

        return .text
    }
}
