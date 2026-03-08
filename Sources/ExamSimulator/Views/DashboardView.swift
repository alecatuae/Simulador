import SwiftUI
import ExamSimulatorCore

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var deps: AppDependencies
    @EnvironmentObject var loc: LocalizationService

    @State private var activeSheet: DashboardSheet?
    @State private var sessionContext: SessionContext?
    @State private var sessionMode: SessionMode = .exam

    enum DashboardSheet: Identifiable {
        case sessionConfig(SessionMode)
        case study(SessionContext)
        case exam(SessionContext)
        var id: String {
            switch self {
            case .sessionConfig(let m): return "config-\(m.rawValue)"
            case .study: return "study"
            case .exam: return "exam"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if viewModel.isLoading {
                ProgressView(loc.t("general.loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if let bank = viewModel.selectedBank {
                bankDetailView(bank)
            } else {
                Text(loc.t("dashboard.selectExam"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .sessionConfig(let mode):
                SessionConfigSheet(
                    bank: viewModel.selectedBank!,
                    mode: mode,
                    progress: viewModel.progress,
                    engine: deps.engine,
                    config: deps.config
                ) { context in
                    activeSheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        activeSheet = mode == .exam ? .exam(context) : .study(context)
                    }
                }
            case .study(let ctx):
                StudyView(viewModel: StudyViewModel(
                    context: ctx,
                    engine: deps.engine,
                    progressRepo: deps.progressRepository,
                    passingScore: deps.config.examDefaults.passingScorePercent
                ))
                .onDisappear { viewModel.reloadProgress() }
            case .exam(let ctx):
                ExamView(viewModel: ExamViewModel(
                    context: ctx,
                    engine: deps.engine,
                    progressRepo: deps.progressRepository,
                    passingScore: deps.config.examDefaults.passingScorePercent
                ))
                .onDisappear { viewModel.reloadProgress() }
            }
        }
    }

    private var sidebar: some View {
        List(viewModel.examBanks, selection: $viewModel.selectedBank) { bank in
            BankSidebarRow(
                bank: bank,
                lastSession: viewModel.lastSession(for: bank),
                isSelected: viewModel.selectedBank?.id == bank.id
            )
            .tag(bank)
        }
        .listStyle(.sidebar)
        .navigationTitle(loc.t("app.title"))
        .toolbar {
            ToolbarItem {
                Button { viewModel.loadData() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
    }

    private func bankDetailView(_ bank: ExamBank) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                bankHeader(bank)
                Divider()
                actionButtons(bank)
                Divider()
                domainSection(bank)
                if let last = viewModel.lastSession(for: bank) {
                    Divider()
                    lastSessionSection(last)
                }
            }
            .padding(32)
        }
    }

    private func bankHeader(_ bank: ExamBank) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bank.metadata.certification)
                .font(.largeTitle.weight(.bold))
            Text(bank.metadata.title)
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label("\(bank.metadata.totalQuestions) \(loc.t("dashboard.questions"))", systemImage: "doc.text")
                Label("\(bank.metadata.domains.count) \(loc.t("dashboard.domains"))", systemImage: "tag")
                Label("\(bank.metadata.simulados.count) simulados", systemImage: "list.number")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func actionButtons(_ bank: ExamBank) -> some View {
        HStack(spacing: 12) {
            ActionButton(
                title: loc.t("dashboard.startExam"),
                icon: "timer",
                color: .accentColor
            ) {
                activeSheet = .sessionConfig(.exam)
            }

            ActionButton(
                title: loc.t("dashboard.studyMode"),
                icon: "book.open",
                color: .green
            ) {
                activeSheet = .sessionConfig(.study)
            }

            ActionButton(
                title: loc.t("dashboard.reviewIncorrect"),
                icon: "exclamationmark.triangle",
                color: .orange,
                isDisabled: viewModel.progress.incorrectHistory.isEmpty
            ) {
                let ctx = viewModel.buildStudySession(filter: .incorrectHistory)
                if let ctx { activeSheet = .study(ctx) }
            }

            ActionButton(
                title: loc.t("dashboard.browseQuestions"),
                icon: "list.bullet",
                color: .purple
            ) {
                let ctx = viewModel.buildStudySession(filter: .all)
                if let ctx { activeSheet = .study(ctx) }
            }
        }
    }

    private func domainSection(_ bank: ExamBank) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t("dashboard.domains"))
                .font(.headline)
            ForEach(bank.metadata.domains) { domain in
                HStack {
                    Text(domain.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(domain.count) \(loc.t("dashboard.questions"))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(
                                width: geo.size.width * Double(domain.count) / Double(bank.metadata.totalQuestions),
                                height: 6
                            )
                    }
                    .frame(width: 80, height: 6)
                }
            }
        }
    }

    private func lastSessionSection(_ session: SessionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t("dashboard.lastSession"))
                .font(.headline)
            HStack(spacing: 20) {
                VStack {
                    Text(session.scorePercentage.formattedPercent)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(session.passed ? .green : .red)
                    Text(session.passed ? loc.t("dashboard.passed") : loc.t("dashboard.failed"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date.formattedShort)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(session.correctCount)/\(session.totalQuestions) correct")
                        .font(.subheadline)
                    Text("Time: \(session.elapsedTime.formattedElapsed)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(loc.t("general.error"))
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(loc.t("general.retry")) { viewModel.loadData() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BankSidebarRow: View {
    let bank: ExamBank
    let lastSession: SessionResult?
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bank.metadata.certification)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            HStack(spacing: 6) {
                Text("\(bank.metadata.totalQuestions) questions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let last = lastSession {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(last.scorePercentage.formattedPercent)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(last.passed ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .secondary : color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDisabled ? Color(nsColor: .controlColor).opacity(0.5) : color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isDisabled ? Color(nsColor: .separatorColor) : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
