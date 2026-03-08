import Foundation

public final class MockAIProvider: AIProvider {
    public var isAvailable: Bool { false }

    public init() {}

    public func explain(question: Question, selectedAnswer: String?) async throws -> String {
        throw AIProviderError.notConfigured
    }

    public func simplify(explanation: String) async throws -> String {
        throw AIProviderError.notConfigured
    }

    public func additionalContext(for question: Question) async throws -> String {
        throw AIProviderError.notConfigured
    }
}
