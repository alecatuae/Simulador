import SwiftUI
import ExamSimulatorCore

struct StudyView: View {
    @StateObject var viewModel: StudyViewModel
    @EnvironmentObject var loc: LocalizationService
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) var dismiss

    @State private var showAIPanel = false
    @State private var showAINotConfigured = false

    var body: some View {
        if viewModel.isFinished, let result = viewModel.sessionResult {
            ResultView(
                viewModel: ReviewViewModel(result: result, bank: viewModel.bank),
                result: result,
                bank: viewModel.bank
            )
        } else {
            studyContent
        }
    }

    private var studyContent: some View {
        VStack(spacing: 0) {
            studyToolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let question = viewModel.currentQuestion {
                        questionHeader(question)
                        questionText(question)
                        alternativesList(question)
                        if viewModel.showExplanation {
                            explanationSection(question)
                        }
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
    }

    private var studyToolbar: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                Text(loc.t("general.back"))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)

            Spacer()

            Text("\(viewModel.currentIndex + 1) / \(viewModel.totalQuestions)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            if viewModel.showExplanation {
                Button {
                    if deps.isAIAvailable {
                        withAnimation(.easeInOut(duration: 0.25)) { showAIPanel.toggle() }
                    } else {
                        showAINotConfigured = true
                    }
                } label: {
                    Label(loc.t("ai.title"), systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(
                            deps.isAIAvailable
                                ? (showAIPanel ? Color.purple : Color.secondary)
                                : Color.secondary.opacity(0.5)
                        )
                }
                .buttonStyle(.plain)
                .help(deps.isAIAvailable ? loc.t("ai.toggle") : loc.t("ai.notConfigured.hint"))
                .popover(isPresented: $showAINotConfigured, arrowEdge: .top) {
                    aiNotConfiguredPopover
                }
            }

            Button {
                viewModel.toggleBookmark()
            } label: {
                Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(viewModel.isBookmarked ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help(viewModel.isBookmarked ? loc.t("study.removeBookmark") : loc.t("study.bookmark"))
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

            Text("#\(question.id)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
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
        guard let selected = viewModel.selectedAnswer else { return .idle }
        if alt.letter == selected {
            return alt.letter == question.correctAnswer ? .correct : .incorrect
        }
        if alt.letter == question.correctAnswer && viewModel.hasAnswered {
            return .correctUnselected
        }
        return .idle
    }

    private func explanationSection(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            resultBanner

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(loc.t("study.explanation"))
                        .font(.headline)
                    Spacer()
                    Picker("", selection: $viewModel.showEnglishExplanation) {
                        Text(loc.t("study.explanationEn")).tag(true)
                        Text(loc.t("study.explanationPtBr")).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                Text(viewModel.showEnglishExplanation ? question.explanationEn : question.explanationPtBr)
                    .font(.body)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            noteSection(question)

            if showAIPanel && deps.isAIAvailable {
                AIAssistantView(
                    aiService: deps.aiService,
                    question: question,
                    selectedAnswer: viewModel.selectedAnswer
                )
                .id(question.id)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeOut(duration: 0.3), value: viewModel.showExplanation)
    }

    private var aiNotConfiguredPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text(loc.t("ai.title"))
                    .font(.headline)
            }
            Text(loc.t("ai.notConfigured.message"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Text(loc.t("ai.notConfigured.hint2"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private var resultBanner: some View {
        HStack(spacing: 12) {
            if viewModel.isCurrentAnswerCorrect == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text(loc.t("study.correct"))
                    .font(.headline)
                    .foregroundStyle(.green)
            } else if viewModel.isCurrentAnswerCorrect == false {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.t("study.incorrect"))
                        .font(.headline)
                        .foregroundStyle(.red)
                    if let q = viewModel.currentQuestion {
                        Text("\(loc.t("study.correctAnswer")): \(q.correctAnswer)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(viewModel.isCurrentAnswerCorrect == true ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func noteSection(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.t("study.note"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextEditor(text: $viewModel.userNote)
                .font(.body)
                .frame(height: 72)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .onChange(of: viewModel.userNote) {
                    viewModel.saveNote()
                }
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(loc.t("exam.previous")) {
                showAIPanel = false
                viewModel.previous()
            }
            .disabled(viewModel.isFirstQuestion)
            .keyboardShortcut(.leftArrow, modifiers: [])

            Spacer()

            if viewModel.isLastQuestion {
                Button(loc.t("general.done")) {
                    viewModel.finishSession()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(viewModel.hasAnswered ? loc.t("exam.next") : loc.t("study.showExplanation")) {
                    if viewModel.hasAnswered {
                        showAIPanel = false
                        viewModel.next()
                    }
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
