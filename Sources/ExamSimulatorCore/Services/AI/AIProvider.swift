import Foundation

public protocol AIProvider {
    var isAvailable: Bool { get }
    /// Auto-explain a question to the student after they answered.
    /// - Parameter language: BCP-47 tag for the desired response language, e.g. "en" or "pt-BR".
    func explain(question: Question, selectedAnswer: String?, language: String) async throws -> String
    /// Continue a conversation with full history + question context.
    /// - Parameter language: BCP-47 tag for the desired response language.
    func chat(messages: [ChatMessage], question: Question, language: String) async throws -> String
    /// Simplify an existing explanation for easier reading.
    func simplify(explanation: String) async throws -> String
    /// Provide extra context about a question's topic.
    func additionalContext(for question: Question) async throws -> String
}

public enum AIProviderError: LocalizedError {
    case notConfigured
    case apiKeyMissing
    case requestFailed(String)
    case rateLimited
    case quotaExceeded

    public var errorDescription: String? {
        switch self {
        case .notConfigured:          return "AI provider is not configured"
        case .apiKeyMissing:          return "API key is missing — configure it in Settings"
        case .requestFailed(let msg): return "Request failed: \(msg)"
        case .rateLimited:            return "Rate limit exceeded. Please wait a moment before trying again."
        case .quotaExceeded:          return "OpenAI quota exhausted. Add credits at platform.openai.com/account/billing."
        }
    }
}

// MARK: - Service facade

public struct AIStudyAssistantService {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    public var isAvailable: Bool { provider.isAvailable }

    public func explain(question: Question, selectedAnswer: String?, language: String = "en") async throws -> String {
        try await provider.explain(question: question, selectedAnswer: selectedAnswer, language: language)
    }

    public func chat(messages: [ChatMessage], question: Question, language: String = "en") async throws -> String {
        try await provider.chat(messages: messages, question: question, language: language)
    }

    public func simplify(explanation: String) async throws -> String {
        try await provider.simplify(explanation: explanation)
    }

    public func additionalContext(for question: Question) async throws -> String {
        try await provider.additionalContext(for: question)
    }
}
