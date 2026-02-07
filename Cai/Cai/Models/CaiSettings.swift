import Foundation

/// Persistent user settings stored in UserDefaults.
/// Provides defaults for search engine, translation language, and LLM model URL.
class CaiSettings: ObservableObject {
    static let shared = CaiSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let searchEngine = "cai_searchEngine"
        static let translationLanguage = "cai_translationLanguage"
        static let modelURL = "cai_modelURL"
    }

    // MARK: - Search Engine

    enum SearchEngine: String, CaseIterable, Identifiable {
        case brave = "Brave"
        case google = "Google"
        case duckDuckGo = "DuckDuckGo"
        case bing = "Bing"

        var id: String { rawValue }

        var searchURLTemplate: String {
            switch self {
            case .brave: return "https://search.brave.com/search?q=%@"
            case .google: return "https://www.google.com/search?q=%@"
            case .duckDuckGo: return "https://duckduckgo.com/?q=%@"
            case .bing: return "https://www.bing.com/search?q=%@"
            }
        }

        func searchURL(for query: String) -> URL? {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let urlString = searchURLTemplate.replacingOccurrences(of: "%@", with: encoded)
            return URL(string: urlString)
        }
    }

    // MARK: - Published Properties

    @Published var searchEngine: SearchEngine {
        didSet { defaults.set(searchEngine.rawValue, forKey: Keys.searchEngine) }
    }

    @Published var translationLanguage: String {
        didSet { defaults.set(translationLanguage, forKey: Keys.translationLanguage) }
    }

    @Published var modelURL: String {
        didSet { defaults.set(modelURL, forKey: Keys.modelURL) }
    }

    // MARK: - Common Languages

    static let commonLanguages = [
        "English", "Spanish", "French", "German", "Italian",
        "Portuguese", "Chinese", "Japanese", "Korean", "Arabic",
        "Russian", "Hindi", "Dutch", "Swedish", "Turkish"
    ]

    // MARK: - Init

    private init() {
        // Load from UserDefaults with sensible defaults
        let engineRaw = defaults.string(forKey: Keys.searchEngine) ?? SearchEngine.brave.rawValue
        self.searchEngine = SearchEngine(rawValue: engineRaw) ?? .brave

        self.translationLanguage = defaults.string(forKey: Keys.translationLanguage) ?? "English"

        self.modelURL = defaults.string(forKey: Keys.modelURL) ?? "http://127.0.0.1:1234"
    }
}
