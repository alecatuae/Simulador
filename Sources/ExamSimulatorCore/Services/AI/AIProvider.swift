import Foundation

public protocol AIProvider {
    var isAvailable: Bool { get }
    func explain(question: Question, selectedAnswer: String?) async throws -> String
    func simplify(explanation: String) async throws -> String
    func additionalContext(for question: Question) async throws -> String
}

public enum AIProviderError: LocalizedError {
    case notConfigured
    case apiKeyMissing
    case requestFailed(String)
    case rateLimited

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "AI provider is not configured"
        case .apiKeyMissing: return "API key is missing. Set the environment variable in AppConfig"
        case .requestFailed(let msg): return "Request failed: \(msg)"
        case .rateLimited: return "Rate limit exceeded. Please wait before trying again"
        }
    }
}

public struct AIStudyAssistantService {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    public var isAvailable: Bool { provider.isAvailable }

    public func explain(question: Question, selectedAnswer: String?) async throws -> String {
        try await provider.explain(question: question, selectedAnswer: selectedAnswer)
    }

    public func simplify(explanation: String) async throws -> String {
        try await provider.simplify(explanation: explanation)
    }

    public func additionalContext(for question: Question) async throws -> String {
        try await provider.additionalContext(for: question)
    }
}
