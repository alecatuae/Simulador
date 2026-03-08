import Foundation
import ExamSimulatorCore

@MainActor
final class StudyViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var selectedAnswer: String?
    @Published var showExplanation = false
    @Published var isBookmarked = false
    @Published var showEnglishExplanation = true
    @Published var userNote: String = ""
    @Published var sessionResult: SessionResult?
    @Published var isFinished = false

    let questions: [Question]
    let bank: ExamBank

    private let engine: ExamEngine
    private let progressRepo: ProgressRepository
    private let passingScore: Double
    private let startTime: Date
    private var progress: UserProgress
    /// Accumulates every answer given across the entire session.
    private var allAnswers: [Int: String] = [:]

    init(
        context: SessionContext,
        engine: ExamEngine,
        progressRepo: ProgressRepository,
        passingScore: Double
    ) {
        self.questions = context.session.questions
        self.bank = context.bank
        self.engine = engine
        self.progressRepo = progressRepo
        self.passingScore = passingScore
        self.startTime = Date()
        self.progress = (try? progressRepo.load()) ?? UserProgress()
        refreshBookmarkState()
    }

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var totalQuestions: Int { questions.count }
    var hasAnswered: Bool { selectedAnswer != nil }
    var isFirstQuestion: Bool { currentIndex == 0 }
    var isLastQuestion: Bool { currentIndex == questions.count - 1 }

    var isCurrentAnswerCorrect: Bool? {
        guard let selected = selectedAnswer, let q = currentQuestion else { return nil }
        return selected == q.correctAnswer
    }

    func selectAnswer(_ letter: String) {
        guard !hasAnswered else { return }
        selectedAnswer = letter
        showExplanation = true
        if let q = currentQuestion {
            allAnswers[q.id] = letter
        }
    }

    func next() {
        guard !isLastQuestion else { return }
        currentIndex += 1
        resetState()
    }

    func previous() {
        guard !isFirstQuestion else { return }
        currentIndex -= 1
        resetState()
    }

    func navigate(to index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentIndex = index
        resetState()
    }

    func toggleBookmark() {
        guard let q = currentQuestion else { return }
        progress.toggleBookmark(questionId: q.id)
        isBookmarked.toggle()
        try? progressRepo.save(progress)
    }

    func saveNote() {
        guard let q = currentQuestion else { return }
        progress.setNote(userNote, bankId: bank.bankId, questionId: q.id)
        try? progressRepo.save(progress)
    }

    func finishSession() {
        let config = SessionConfig(
            bankId: bank.bankId,
            mode: .study,
            filter: .all
        )
        let session = ExamSession(config: config, questions: questions, startTime: startTime)
        session.answers = allAnswers
        session.endTime = Date()

        let result = engine.calculateResult(
            session: session,
            passingScore: passingScore,
            certification: bank.metadata.certification
        )
        sessionResult = result
        isFinished = true
        try? progressRepo.addSession(result)
    }

    private func resetState() {
        // Restore the answer for the question we're navigating back to (if already answered).
        if let q = currentQuestion, let prior = allAnswers[q.id] {
            selectedAnswer = prior
            showExplanation = true
        } else {
            selectedAnswer = nil
            showExplanation = false
        }
        refreshBookmarkState()
        loadUserNote()
    }

    private func refreshBookmarkState() {
        guard let q = currentQuestion else { return }
        isBookmarked = progress.bookmarks.contains(q.id)
    }

    private func loadUserNote() {
        guard let q = currentQuestion else { return }
        userNote = progress.note(bankId: bank.bankId, questionId: q.id) ?? ""
    }
}
