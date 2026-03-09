import SwiftUI
import ExamSimulatorCore

struct SessionConfigSheet: View {
    let bank: ExamBank
    let mode: SessionMode
    let progress: UserProgress
    let engine: ExamEngine
    let config: AppConfig
    let onStart: (SessionContext) -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var loc: LocalizationService

    @State private var selectedFilter: FilterOption = .all
    @State private var randomizeQuestions: Bool
    @State private var questionCount: Int = 0

    init(
        bank: ExamBank,
        mode: SessionMode,
        progress: UserProgress,
        engine: ExamEngine,
        config: AppConfig,
        onStart: @escaping (SessionContext) -> Void
    ) {
        self.bank = bank
        self.mode = mode
        self.progress = progress
        self.engine = engine
        self.config = config
        self.onStart = onStart
        _randomizeQuestions = State(initialValue: config.examDefaults.randomizeQuestions)
    }

    // MARK: - Filter options

    enum FilterOption: Identifiable, Hashable {
        case all
        case simulado(Int)
        case domain(String)
        case bookmarked
        case incorrect

        var id: String {
            switch self {
            case .all: return "all"
            case .simulado(let n): return "sim-\(n)"
            case .domain(let d): return "dom-\(d)"
            case .bookmarked: return "bookmarked"
            case .incorrect: return "incorrect"
            }
        }

        func label(loc: LocalizationService) -> String {
            switch self {
            case .all: return loc.t("session.scope.all")
            case .simulado(let n): return loc.t("session.scope.simulado\(n)")
            case .domain(let d): return d
            case .bookmarked: return loc.t("session.scope.bookmarked")
            case .incorrect: return loc.t("session.scope.incorrect")
            }
        }

        var questionFilter: QuestionFilter {
            switch self {
            case .all: return .all
            case .simulado(let n): return .bySimulado(n)
            case .domain(let d): return .byDomain(d)
            case .bookmarked: return .bookmarked
            case .incorrect: return .incorrectHistory
            }
        }
    }

    private var filterOptions: [FilterOption] {
        var options: [FilterOption] = [.all]
        for sim in bank.metadata.simulados {
            options.append(.simulado(sim.number))
        }
        for domain in bank.metadata.domains.map({ $0.name }).sorted() {
            options.append(.domain(domain))
        }
        if !progress.bookmarks.isEmpty { options.append(.bookmarked) }
        if !progress.incorrectHistory.isEmpty { options.append(.incorrect) }
        return options
    }

    // MARK: - Computed

    private var availableCount: Int {
        engine.filterQuestions(
            bank.questions,
            filter: selectedFilter.questionFilter,
            bookmarkedIds: progress.bookmarks,
            incorrectIds: progress.incorrectHistory
        ).count
    }

    private var effectiveCount: Int {
        questionCount == 0 ? availableCount : min(questionCount, availableCount)
    }

    private var isUsingAll: Bool { effectiveCount == availableCount }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(minWidth: 420, idealWidth: 500, maxWidth: 580)
        .onAppear {
            questionCount = availableCount
        }
        .onChange(of: selectedFilter) {
            let available = availableCount
            if questionCount > available || questionCount == 0 {
                questionCount = available
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Image(systemName: mode == .exam ? "timer" : "book")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(loc.t("session.configTitle"))
                .font(.title2.weight(.semibold))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }

    private var content: some View {
        Form {
            // --- Scope ---
            Section(loc.t("session.scope")) {
                Picker("", selection: $selectedFilter) {
                    ForEach(filterOptions) { option in
                        Text(option.label(loc: loc)).tag(option)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            // --- Options ---
            Section(loc.t("session.options")) {
                orderRow
                questionCountRow
            }

            // --- Timer (exam mode only) ---
            if mode == .exam {
                Section("Timer") {
                    Label(
                        "\(config.examDefaults.timerMinutes) \(loc.t("general.minutes"))",
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal)
    }

    private var orderRow: some View {
        HStack {
            Text(loc.t("session.order"))
                .font(.subheadline)
            Spacer()
            Picker("", selection: $randomizeQuestions) {
                Text(loc.t("session.order.random")).tag(true)
                Text(loc.t("session.order.sequential")).tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .labelsHidden()
        }
    }

    private var questionCountRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(loc.t("session.questionCount"))
                    .font(.subheadline)
                Spacer()
                Text("\(effectiveCount) \(loc.t("session.questionCount.of")) \(availableCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Stepper(
                    "",
                    value: $questionCount,
                    in: 1...max(1, availableCount),
                    step: 1
                )
                .labelsHidden()
                .frame(width: 80)
            }

            if !isUsingAll {
                Button(String(format: loc.t("session.questionCount.useAll"), availableCount)) {
                    questionCount = availableCount
                }
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(effectiveCount) \(loc.t("dashboard.questions"))")
                    .font(.subheadline.weight(.semibold))
                if availableCount == 0 {
                    Text("Select a different scope")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Button(loc.t("session.cancel")) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(loc.t("session.start")) {
                startSession()
            }
            .buttonStyle(.borderedProminent)
            .disabled(availableCount == 0)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }

    // MARK: - Actions

    private func startSession() {
        let limit = isUsingAll ? nil : effectiveCount
        let sessionConfig = SessionConfig(
            bankId: bank.bankId,
            mode: mode,
            filter: selectedFilter.questionFilter,
            timeLimit: mode == .exam ? config.examDefaults.timerSeconds : nil,
            randomizeQuestions: randomizeQuestions,
            randomizeAnswers: config.examDefaults.randomizeAnswers,
            questionLimit: limit
        )
        let session = engine.buildSession(
            config: sessionConfig,
            questions: bank.questions,
            bookmarkedIds: progress.bookmarks,
            incorrectIds: progress.incorrectHistory
        )
        onStart(SessionContext(session: session, bank: bank))
    }
}
