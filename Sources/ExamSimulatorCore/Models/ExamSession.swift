import Foundation

public enum SessionMode: String, Codable, CaseIterable {
    case study
    case exam
    case review
}

public enum QuestionFilter: Hashable {
    case all
    case bySimulado(Int)
    case byDomain(String)
    case incorrectHistory
    case bookmarked
}

public struct SessionConfig {
    public let bankId: String
    public let mode: SessionMode
    public let filter: QuestionFilter
    public let timeLimit: TimeInterval?
    public let randomizeQuestions: Bool
    public let randomizeAnswers: Bool
    /// Maximum number of questions to include. `nil` means use all available.
    public let questionLimit: Int?
    /// Minimum score (0–100) required to pass. Sourced from the exam bank metadata.
    public let passingScorePercent: Double

    public init(
        bankId: String,
        mode: SessionMode,
        filter: QuestionFilter = .all,
        timeLimit: TimeInterval? = nil,
        randomizeQuestions: Bool = true,
        randomizeAnswers: Bool = false,
        questionLimit: Int? = nil,
        passingScorePercent: Double = 70.0
    ) {
        self.bankId = bankId
        self.mode = mode
        self.filter = filter
        self.timeLimit = timeLimit
        self.randomizeQuestions = randomizeQuestions
        self.randomizeAnswers = randomizeAnswers
        self.questionLimit = questionLimit
        self.passingScorePercent = passingScorePercent
    }
}

public final class ExamSession {
    public let id: UUID
    public let config: SessionConfig
    public let questions: [Question]
    public var currentIndex: Int
    public var answers: [Int: String]
    public var flaggedIds: Set<Int>
    public let startTime: Date
    public var endTime: Date?

    public init(config: SessionConfig, questions: [Question], startTime: Date = Date()) {
        self.id = UUID()
        self.config = config
        self.questions = questions
        self.currentIndex = 0
        self.answers = [:]
        self.flaggedIds = []
        self.startTime = startTime
    }

    public var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public var answeredCount: Int { answers.count }
    public var unansweredCount: Int { questions.count - answers.count }
    public var isComplete: Bool { endTime != nil }
}
