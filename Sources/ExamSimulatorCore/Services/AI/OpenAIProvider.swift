import Foundation

/// Production provider that calls the OpenAI Chat Completions API.
/// The API key is resolved via a closure so changes to UserDefaults
/// are reflected immediately without re-creating the service.
public final class OpenAIProvider: AIProvider {

    private let config: AIProviderConfig
    private let apiKeyResolver: () -> String

    private func systemPrompt(language: String) -> String {
        let langInstruction = language.lowercased().hasPrefix("pt")
            ? "Always respond in Brazilian Portuguese (pt-BR)."
            : "Always respond in English."
        return """
        You are a concise IT certification exam study assistant. \
        Answer in 3-5 sentences. Focus on what the student needs \
        to know for the exam. Be direct and clear. \(langInstruction)
        """
    }

    public var isAvailable: Bool { !apiKeyResolver().isEmpty }

    public init(config: AIProviderConfig, apiKeyResolver: @escaping () -> String) {
        self.config = config
        self.apiKeyResolver = apiKeyResolver
    }

    // MARK: - AIProvider

    public func explain(question: Question, selectedAnswer: String?, language: String) async throws -> String {
        let correct = question.alternatives.first { $0.letter == question.correctAnswer }
        let selected = selectedAnswer.flatMap { l in question.alternatives.first { $0.letter == l } }
        let explanation = language.lowercased().hasPrefix("pt")
            ? question.explanationPtBr : question.explanationEn

        var prompt = """
        Question (#\(question.id)): \(question.question)
        Domain: \(question.domain)
        Correct answer: \(question.correctAnswer). \(correct?.text ?? "")
        Official explanation: \(explanation)
        """

        if let selected, selected.letter != question.correctAnswer {
            prompt += "\nStudent's answer: \(selected.letter). \(selected.text) (incorrect)"
        }

        prompt += "\n\nBriefly explain why \(question.correctAnswer) is correct and why the other options are not."

        return try await complete(messages: [
            .init(role: .system, content: systemPrompt(language: language)),
            .init(role: .user,   content: prompt)
        ])
    }

    public func chat(messages: [ChatMessage], question: Question, language: String) async throws -> String {
        let explanation = language.lowercased().hasPrefix("pt")
            ? question.explanationPtBr : question.explanationEn
        let context = ChatMessage(role: .system, content: """
        \(systemPrompt(language: language))
        The student is reviewing question #\(question.id) from domain '\(question.domain)'.
        Question: \(question.question)
        Correct answer: \(question.correctAnswer).
        Official explanation: \(explanation)
        """)
        return try await complete(messages: [context] + messages)
    }

    public func simplify(explanation: String) async throws -> String {
        return try await complete(messages: [
            .init(role: .system, content: systemPrompt(language: "en")),
            .init(role: .user,   content: "Simplify this in 2-3 sentences for a beginner:\n\n\(explanation)")
        ])
    }

    public func additionalContext(for question: Question) async throws -> String {
        return try await complete(messages: [
            .init(role: .system, content: systemPrompt(language: "en")),
            .init(role: .user,   content:
                "Give 2-3 sentences of extra context about: \(question.question) (Domain: \(question.domain))")
        ])
    }

    // MARK: - Private

    private func complete(messages: [ChatMessage]) async throws -> String {
        let key = apiKeyResolver()
        guard !key.isEmpty else { throw AIProviderError.apiKeyMissing }

        guard let url = URL(string: "\(config.baseURL)/chat/completions") else {
            throw AIProviderError.requestFailed("Invalid base URL: \(config.baseURL)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)",    forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let payload: [String: Any] = [
            "model":      config.model,
            "messages":   messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": 600,
            "temperature": 0.3
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Parse API-level error (may appear on 4xx/5xx)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            let httpCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if httpCode == 429 { throw AIProviderError.rateLimited }
            throw AIProviderError.requestFailed(message)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AIProviderError.requestFailed("HTTP \(code)")
        }

        guard
            let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices  = json["choices"] as? [[String: Any]],
            let first    = choices.first,
            let message  = first["message"] as? [String: Any],
            let content  = message["content"] as? String
        else {
            throw AIProviderError.requestFailed("Unexpected response format")
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
