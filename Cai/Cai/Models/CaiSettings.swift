import Foundation

/// Persistent user settings stored in UserDefaults.
class CaiSettings: ObservableObject {
    static let shared = CaiSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let searchURL = "cai_searchURL"
        static let translationLanguage = "cai_translationLanguage"
        static let modelProvider = "cai_modelProvider"
        static let customModelURL = "cai_customModelURL"
    }

    // MARK: - Model Provider

    enum ModelProvider: String, CaseIterable, Identifiable {
        case lmstudio = "LM Studio"
        case ollama = "Ollama"
        case custom = "Custom"

        var id: String { rawValue }

        /// Base URL (without /v1) for each provider
        var defaultURL: String {
            switch self {
            case .lmstudio: return "http://127.0.0.1:1234"
            case .ollama: return "http://127.0.0.1:11434"
            case .custom: return ""
            }
        }
    }

    // MARK: - Published Properties

    /// Base search URL. Query is percent-encoded and appended.
    @Published var searchURL: String {
        didSet { defaults.set(searchURL, forKey: Keys.searchURL) }
    }

    @Published var translationLanguage: String {
        didSet { defaults.set(translationLanguage, forKey: Keys.translationLanguage) }
    }

    @Published var modelProvider: ModelProvider {
        didSet { defaults.set(modelProvider.rawValue, forKey: Keys.modelProvider) }
    }

    /// Only used when modelProvider == .custom
    @Published var customModelURL: String {
        didSet { defaults.set(customModelURL, forKey: Keys.customModelURL) }
    }

    /// Resolved model base URL based on provider selection
    var modelURL: String {
        switch modelProvider {
        case .lmstudio, .ollama:
            return modelProvider.defaultURL
        case .custom:
            return customModelURL
        }
    }

    // MARK: - Common Languages

    static let commonLanguages = [
        "English", "Spanish", "French", "German", "Italian",
        "Portuguese", "Chinese", "Japanese", "Korean", "Arabic",
        "Russian", "Hindi", "Dutch", "Swedish", "Turkish"
    ]

    // MARK: - Init

    private init() {
        self.searchURL = defaults.string(forKey: Keys.searchURL)
            ?? "https://search.brave.com/search?q="

        self.translationLanguage = defaults.string(forKey: Keys.translationLanguage)
            ?? "English"

        let providerRaw = defaults.string(forKey: Keys.modelProvider) ?? ModelProvider.lmstudio.rawValue
        self.modelProvider = ModelProvider(rawValue: providerRaw) ?? .lmstudio

        self.customModelURL = defaults.string(forKey: Keys.customModelURL)
            ?? "http://127.0.0.1:8080"
    }
}
