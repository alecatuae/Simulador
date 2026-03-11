import SwiftUI
import ExamSimulatorCore

struct ExamView: View {
    @StateObject var viewModel: ExamViewModel
    @EnvironmentObject var loc: LocalizationService
    @Environment(\.dismiss) var dismiss

    @State private var showNavigator = false
    @State private var showCancelConfirmation = false

    var body: some View {
        if viewModel.isSubmitted, let result = viewModel.sessionResult {
            ResultView(
                viewModel: ReviewViewModel(result: result, bank: viewModel.bank),
                result: result,
                bank: viewModel.bank
            )
        } else {
            examContent
        }
    }

    private var examContent: some View {
        VStack(spacing: 0) {
            examToolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let question = viewModel.currentQuestion {
                        questionHeader(question)
                        questionText(question)
                        alternativesList(question)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 28)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            Divider()
            navigationBar
        }
        .frame(minWidth: 800, minHeight: 600)
        .alert(loc.t("exam.confirmSubmit.title"), isPresented: $viewModel.showSubmitConfirmation) {
            Button(loc.t("exam.confirmSubmit.cancel"), role: .cancel) {}
            Button(loc.t("exam.confirmSubmit.submit"), role: .destructive) {
                viewModel.submitExam()
            }
        } message: {
            Text(String(format: loc.t("exam.confirmSubmit.message"), viewModel.unansweredCount))
        }
        .alert(loc.t("exam.confirmCancel.title"), isPresented: $showCancelConfirmation) {
            Button(loc.t("exam.confirmCancel.stay"), role: .cancel) {}
            Button(loc.t("exam.confirmCancel.confirm"), role: .destructive) {
                dismiss()
            }
        } message: {
            Text(loc.t("exam.confirmCancel.message"))
        }
    }

    private var examToolbar: some View {
        HStack(spacing: 16) {
            // Cancel / exit exam button
            Button {
                showCancelConfirmation = true
            } label: {
                Label(loc.t("exam.cancelExam"), systemImage: "xmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if viewModel.mode == .exam, let _ = viewModel.timeRemaining as TimeInterval? {
                TimerView(timeRemaining: viewModel.timeRemaining, totalTime: 5400)
            }

            Spacer()

            Text("\(loc.t("exam.question")) \(viewModel.currentIndex + 1) \(loc.t("exam.of")) \(viewModel.totalQuestions)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(viewModel.answeredCount)", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
                Label("\(viewModel.unansweredCount)", systemImage: "circle.dashed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(viewModel.flaggedIds.count)", systemImage: "flag")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()

            Button {
                showNavigator.toggle()
            } label: {
                Image(systemName: "square.grid.3x3")
            }
            .popover(isPresented: $showNavigator) {
                QuestionNavigatorView(
                    questions: viewModel.questions,
                    answeredIds: Set(viewModel.selectedAnswers.keys),
                    flaggedIds: viewModel.flaggedIds,
                    currentIndex: viewModel.currentIndex,
                    onSelect: { idx in
                        viewModel.navigate(to: idx)
                        showNavigator = false
                    }
                )
                .padding(8)
                .frame(minWidth: 360)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func questionHeader(_ question: Question) -> some View {
        HStack {
            Text(question.domain)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())

            Spacer()

            Button {
                viewModel.toggleFlag()
            } label: {
                Label(
                    viewModel.isCurrentFlagged ? loc.t("exam.unflag") : loc.t("exam.flag"),
                    systemImage: viewModel.isCurrentFlagged ? "flag.fill" : "flag"
                )
                .font(.subheadline)
                .foregroundStyle(viewModel.isCurrentFlagged ? .orange : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func questionText(_ question: Question) -> some View {
        Text(question.question)
            .font(.title3.weight(.medium))
            .lineSpacing(4)
            .textSelection(.enabled)
    }

    private func alternativesList(_ question: Question) -> some View {
        VStack(spacing: 8) {
            ForEach(question.alternatives) { alt in
                AlternativeRow(
                    alternative: alt,
                    state: alternativeState(alt, question: question),
                    onTap: { viewModel.selectAnswer(alt.letter) }
                )
            }
        }
    }

    private func alternativeState(_ alt: Alternative, question: Question) -> AlternativeRow.AlternativeState {
        guard let selected = viewModel.selectedAnswers[question.id] else { return .idle }
        if alt.letter == selected { return .selected }
        return .idle
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            Button(loc.t("exam.previous")) {
                viewModel.previous()
            }
            .disabled(viewModel.isFirstQuestion)
            .keyboardShortcut(.leftArrow, modifiers: [])

            Spacer()

            if viewModel.isLastQuestion {
                Button(loc.t("exam.submit")) {
                    viewModel.requestSubmit()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            } else {
                Button(loc.t("exam.next")) {
                    viewModel.next()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.rightArrow, modifiers: [])
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
