import Foundation
import ExamSimulatorCore

@MainActor
final class ExamViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var selectedAnswers: [Int: String] = [:]
    @Published var flaggedIds: Set<Int> = []
    @Published var timeRemaining: TimeInterval = 0
    @Published var isSubmitted = false
    @Published var sessionResult: SessionResult?
    @Published var showSubmitConfirmation = false

    let questions: [Question]
    let bank: ExamBank
    let mode: SessionMode

    private let engine: ExamEngine
    private let progressRepo: ProgressRepository
    private let passingScore: Double
    private let startTime: Date
    private var timer: Timer?
    private let timeLimit: TimeInterval?

    init(context: SessionContext, engine: ExamEngine, progressRepo: ProgressRepository, passingScore: Double) {
        self.questions = context.session.questions
        self.bank = context.bank
        self.mode = context.session.config.mode
        self.engine = engine
        self.progressRepo = progressRepo
        self.passingScore = passingScore
        self.startTime = Date()
        self.timeLimit = context.session.config.timeLimit
        self.timeRemaining = context.session.config.timeLimit ?? 0

        if mode == .exam, timeLimit != nil {
            startTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var totalQuestions: Int { questions.count }
    var isFirstQuestion: Bool { currentIndex == 0 }
    var isLastQuestion: Bool { currentIndex == questions.count - 1 }
    var answeredCount: Int { selectedAnswers.count }
    var unansweredCount: Int { questions.count - selectedAnswers.count }

    var currentSelectedAnswer: String? {
        guard let q = currentQuestion else { return nil }
        return selectedAnswers[q.id]
    }

    var isCurrentFlagged: Bool {
        guard let q = currentQuestion else { return false }
        return flaggedIds.contains(q.id)
    }

    func selectAnswer(_ letter: String) {
        guard let q = currentQuestion else { return }
        selectedAnswers[q.id] = letter
    }

    func clearAnswer() {
        guard let q = currentQuestion else { return }
        selectedAnswers.removeValue(forKey: q.id)
    }

    func toggleFlag() {
        guard let q = currentQuestion else { return }
        if flaggedIds.contains(q.id) {
            flaggedIds.remove(q.id)
        } else {
            flaggedIds.insert(q.id)
        }
    }

    func navigate(to index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentIndex = index
    }

    func next() { if !isLastQuestion { currentIndex += 1 } }
    func previous() { if !isFirstQuestion { currentIndex -= 1 } }

    func requestSubmit() {
        if unansweredCount > 0 {
            showSubmitConfirmation = true
        } else {
            submitExam()
        }
    }

    func submitExam() {
        stopTimer()
        let session = buildSession()
        let result = engine.calculateResult(
            session: session,
            passingScore: passingScore,
            certification: bank.metadata.certification
        )
        sessionResult = result
        isSubmitted = true
        try? progressRepo.addSession(result)
    }

    private func buildSession() -> ExamSession {
        let config = SessionConfig(
            bankId: bank.bankId,
            mode: mode,
            filter: .all,
            timeLimit: timeLimit
        )
        let session = ExamSession(config: config, questions: questions, startTime: startTime)
        session.answers = selectedAnswers
        session.flaggedIds = flaggedIds
        session.endTime = Date()
        return session
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.submitExam()
                }
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
