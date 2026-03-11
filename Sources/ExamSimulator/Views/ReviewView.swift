import SwiftUI
import ExamSimulatorCore

struct ReviewView: View {
    @StateObject var viewModel: ReviewViewModel
    @EnvironmentObject var loc: LocalizationService
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) var dismiss

    @State private var showEnglishExplanation = true
    @State private var showAIPanel = false

    var body: some View {
        VStack(spacing: 0) {
            reviewToolbar
            Divider()

            if viewModel.filteredResults.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let question = viewModel.currentQuestion,
                           let result = viewModel.currentResult {
                            questionHeader(question, result: result)
                            questionText(question)
                            alternativesList(question, result: result)
                            explanationSection(question)
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
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private var reviewToolbar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                Text(loc.t("general.back"))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)

            Spacer()

            Picker("", selection: $viewModel.selectedFilter) {
                ForEach(ReviewViewModel.ReviewFilter.allCases) { filter in
                    Text(loc.t(filter.rawValue)).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)
            .onChange(of: viewModel.selectedFilter) {
                viewModel.onFilterChange()
            }

            Spacer()

            if deps.isAIAvailable, viewModel.totalFiltered > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showAIPanel.toggle() }
                } label: {
                    Label(loc.t("ai.title"), systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(showAIPanel ? Color.purple : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(loc.t("ai.toggle"))
            }

            if viewModel.totalFiltered > 0 {
                Text("\(viewModel.currentIndex + 1) / \(viewModel.totalFiltered)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func questionHeader(_ question: Question, result: QuestionResult) -> some View {
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

            if result.wasFlagged {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()

            resultBadge(result)
        }
    }

    private func resultBadge(_ result: QuestionResult) -> some View {
        HStack(spacing: 4) {
            Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(result.isCorrect ? loc.t("study.correct") : loc.t("study.incorrect"))
                .font(.caption.weight(.semibold))
        }
        .font(.caption)
        .foregroundStyle(result.isCorrect ? .green : .red)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background((result.isCorrect ? Color.green : Color.red).opacity(0.1))
        .clipShape(Capsule())
    }

    private func questionText(_ question: Question) -> some View {
        Text(question.question)
            .font(.title3.weight(.medium))
            .lineSpacing(4)
            .textSelection(.enabled)
    }

    private func alternativesList(_ question: Question, result: QuestionResult) -> some View {
        VStack(spacing: 8) {
            ForEach(question.alternatives) { alt in
                AlternativeRow(
                    alternative: alt,
                    state: reviewAlternativeState(alt, result: result),
                    onTap: {}
                )
            }
        }
    }

    private func reviewAlternativeState(_ alt: Alternative, result: QuestionResult) -> AlternativeRow.AlternativeState {
        let isSelected = alt.letter == result.selectedAnswer
        let isCorrect = alt.letter == result.correctAnswer

        if isSelected && isCorrect { return .correct }
        if isSelected && !isCorrect { return .incorrect }
        if !isSelected && isCorrect { return .correctUnselected }
        return .idle
    }

    private func explanationSection(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.t("review.explanation"))
                    .font(.headline)
                Spacer()
                Picker("", selection: $showEnglishExplanation) {
                    Text(loc.t("study.explanationEn")).tag(true)
                    Text(loc.t("study.explanationPtBr")).tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            Text(showEnglishExplanation ? question.explanationEn : question.explanationPtBr)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if !question.note.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text(question.note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(nsColor: .controlColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if showAIPanel, deps.isAIAvailable,
               let result = viewModel.currentResult {
                AIAssistantView(
                    aiService: deps.aiService,
                    question: question,
                    selectedAnswer: result.selectedAnswer
                )
                .id(question.id)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(loc.t("exam.previous")) {
                showAIPanel = false
                viewModel.previous()
            }
            .disabled(viewModel.isFirstItem)
            .keyboardShortcut(.leftArrow, modifiers: [])

            Spacer()

            Button(loc.t("exam.next")) {
                showAIPanel = false
                viewModel.next()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLastItem)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(loc.t("review.noResults"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
