import Foundation
import ExamSimulatorCore

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var examBanks: [ExamBank] = []
    @Published var selectedBank: ExamBank?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var progress: UserProgress = UserProgress()

    private var bankRepo: ExamBankRepository?
    private var progressRepo: ProgressRepository?
    private var config: AppConfig?
    private var engine: ExamEngine?

    func configure(
        bankRepo: ExamBankRepository,
        progressRepo: ProgressRepository,
        config: AppConfig,
        engine: ExamEngine
    ) {
        self.bankRepo = bankRepo
        self.progressRepo = progressRepo
        self.config = config
        self.engine = engine
    }

    func loadData() {
        guard let bankRepo, let progressRepo else { return }
        isLoading = true
        errorMessage = nil

        do {
            examBanks = try bankRepo.loadAll()
            progress = (try? progressRepo.load()) ?? UserProgress()
            if selectedBank == nil {
                selectedBank = examBanks.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reloadProgress() {
        guard let progressRepo else { return }
        progress = (try? progressRepo.load()) ?? UserProgress()
    }

    func buildStudySession(filter: QuestionFilter) -> SessionContext? {
        guard let bank = selectedBank, let engine, let config else { return nil }
        let sessionConfig = SessionConfig(
            bankId: bank.bankId,
            mode: .study,
            filter: filter,
            timeLimit: nil,
            randomizeQuestions: config.examDefaults.randomizeQuestions,
            randomizeAnswers: config.examDefaults.randomizeAnswers
        )
        let session = engine.buildSession(
            config: sessionConfig,
            questions: bank.questions,
            bookmarkedIds: progress.bookmarks,
            incorrectIds: progress.incorrectHistory
        )
        return SessionContext(session: session, bank: bank)
    }

    func buildExamSession(filter: QuestionFilter) -> SessionContext? {
        guard let bank = selectedBank, let engine, let config else { return nil }
        let sessionConfig = SessionConfig(
            bankId: bank.bankId,
            mode: .exam,
            filter: filter,
            timeLimit: config.examDefaults.timerSeconds,
            randomizeQuestions: config.examDefaults.randomizeQuestions,
            randomizeAnswers: config.examDefaults.randomizeAnswers
        )
        let session = engine.buildSession(
            config: sessionConfig,
            questions: bank.questions,
            bookmarkedIds: progress.bookmarks,
            incorrectIds: progress.incorrectHistory
        )
        return SessionContext(session: session, bank: bank)
    }

    func domainFilters(for bank: ExamBank) -> [QuestionFilter] {
        let domains = Set(bank.questions.map { $0.domain }).sorted()
        return domains.map { .byDomain($0) }
    }

    func lastSession(for bank: ExamBank) -> SessionResult? {
        progress.lastSession(for: bank.bankId)
    }
}

struct SessionContext {
    let session: ExamSession
    let bank: ExamBank
}
