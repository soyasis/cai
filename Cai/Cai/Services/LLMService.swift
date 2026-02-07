import Foundation

// MARK: - LLM Service

/// Communicates with a local OpenAI-compatible API (LM Studio, Ollama, etc.)
/// All methods are isolated to the actor to ensure thread safety.
actor LLMService {

    static let shared = LLMService()

    // MARK: - Status

    struct Status {
        let available: Bool
        let modelName: String?
        let error: String?
    }

    /// Checks if the LLM server is reachable by hitting GET /v1/models.
    func checkStatus() async -> Status {
        let baseURL = await MainActor.run { CaiSettings.shared.modelURL }
        guard !baseURL.isEmpty,
              baseURL.hasPrefix("http"),
              let url = URL(string: "\(baseURL)/v1/models") else {
            return Status(available: false, modelName: nil, error: "Invalid model URL")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return Status(available: false, modelName: nil, error: "Server returned non-200")
            }
            // Try to extract first model name
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["data"] as? [[String: Any]],
               let first = models.first,
               let modelId = first["id"] as? String {
                return Status(available: true, modelName: modelId, error: nil)
            }
            return Status(available: true, modelName: nil, error: nil)
        } catch {
            return Status(available: false, modelName: nil, error: error.localizedDescription)
        }
    }

    // MARK: - Generation

    /// Sends a chat completion request and returns the assistant's response text.
    func generate(systemPrompt: String? = nil, userPrompt: String) async throws -> String {
        let baseURL = await MainActor.run { CaiSettings.shared.modelURL }
        guard !baseURL.isEmpty,
              baseURL.hasPrefix("http"),
              let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw LLMError.invalidURL
        }

        var messages: [ChatMessage] = []
        if let system = systemPrompt {
            messages.append(ChatMessage(role: "system", content: system))
        }
        messages.append(ChatMessage(role: "user", content: userPrompt))

        let body = ChatRequest(
            model: "", // Empty string — server uses its loaded model
            messages: messages,
            temperature: 0.3,
            max_tokens: 1024
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw LLMError.timeout
            case .cannotConnectToHost, .networkConnectionLost, .cannotFindHost:
                throw LLMError.connectionFailed
            default:
                throw LLMError.connectionFailed
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.serverError(http.statusCode, body)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw LLMError.emptyResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Action Methods

    func summarize(_ text: String) async throws -> String {
        try await generate(userPrompt: """
            Summarize the following text in 2-3 concise sentences. Only output the summary, nothing else.

            Text:
            \(text)

            Summary:
            """)
    }

    func translate(_ text: String, to language: String) async throws -> String {
        try await generate(userPrompt: """
            Translate the following text to \(language). Only output the translation, nothing else.

            Text:
            \(text)

            Translation:
            """)
    }

    func define(_ word: String) async throws -> String {
        try await generate(userPrompt: """
            Define "\(word)" concisely. Include:
            1. Part of speech
            2. Definition
            3. Example sentence

            Keep it brief and clear.
            """)
    }

    func explain(_ text: String) async throws -> String {
        try await generate(userPrompt: """
            Explain "\(text)" concisely in under 150 words. Include:
            1. What it means or refers to
            2. Why it's important or how it's used
            3. A brief example if helpful

            Keep it clear and easy to understand.
            """)
    }

    func customAction(_ text: String, instruction: String) async throws -> String {
        try await generate(
            systemPrompt: "You are a helpful assistant. The user has selected some text and wants you to process it according to their instruction. Only output the result, nothing else.",
            userPrompt: """
                Instruction: \(instruction)

                Text:
                \(text)
                """
        )
    }
}

// MARK: - API Types

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String
        }
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String)
    case emptyResponse
    case connectionFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid model URL. Check Settings \u{2192} Model Provider."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let code, let body):
            return "Server error (\(code)): \(body)"
        case .emptyResponse:
            return "Empty response from model."
        case .connectionFailed:
            return "Could not connect to LLM server. Is it running?"
        case .timeout:
            return "Request timed out. Is your LLM server running?"
        }
    }
}
