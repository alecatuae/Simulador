import Foundation

public struct SessionResult: Codable, Identifiable {
    public let id: UUID
    public let bankId: String
    public let certification: String
    public let mode: SessionMode
    public let date: Date
    public let totalQuestions: Int
    public let correctCount: Int
    public let incorrectCount: Int
    public let skippedCount: Int
    public let elapsedTime: TimeInterval
    public let passingScore: Double
    public let domainScores: [DomainScore]
    public let questionResults: [QuestionResult]

    public var scorePercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions) * 100
    }

    public var passed: Bool {
        scorePercentage >= passingScore
    }
}

public struct DomainScore: Codable, Identifiable {
    public var id: String { domain }
    public let domain: String
    public let correct: Int
    public let total: Int

    public var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}

public struct QuestionResult: Codable, Identifiable {
    public var id: Int { questionId }
    public let questionId: Int
    public let selectedAnswer: String?
    public let correctAnswer: String
    public let isCorrect: Bool
    public let wasFlagged: Bool
}
