import SwiftUI
import ExamSimulatorCore

// MARK: - BrowseQuestionsView

struct BrowseQuestionsView: View {
    @StateObject var viewModel: BrowseQuestionsViewModel
    @EnvironmentObject var loc: LocalizationService
    @Environment(\.dismiss) private var dismiss

    @State private var editingQuestion: Question?
    @State private var showDiscardAlert = false
    @State private var showSaveError = false

    var body: some View {
        VStack(spacing: 0) {
            browseToolbar
            Divider()
            bankSettingsBar
            Divider()
            content
        }
        .frame(minWidth: 900, minHeight: 580)
        .sheet(item: $editingQuestion) { question in
            QuestionEditorSheet(
                question: question,
                availableDomains: viewModel.availableDomains
            ) { updated in
                viewModel.update(updated)
            }
            .environmentObject(loc)
        }
        .alert(loc.t("browse.confirmDiscard.title"), isPresented: $showDiscardAlert) {
            Button(loc.t("general.cancel"), role: .cancel) {}
            Button(loc.t("browse.discard"), role: .destructive) {
                viewModel.discardChanges()
                dismiss()
            }
        } message: {
            Text(loc.t("browse.confirmDiscard.message"))
        }
        .alert(loc.t("general.error"), isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.saveError ?? "")
        }
        .onChange(of: viewModel.saveError) {
            if viewModel.saveError != nil { showSaveError = true }
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView(loc.t("general.loading"))
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Bank Settings Bar

    private var bankSettingsBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.accentColor)
            Text(loc.t("browse.passingScore"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(format: "%.0f%%", viewModel.bank.metadata.passingScorePercent))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, alignment: .leading)

            Stepper(
                "",
                value: $viewModel.bank.metadata.passingScorePercent,
                in: 1...100,
                step: 5
            )
            .labelsHidden()
            .frame(width: 80)
            .help(loc.t("browse.passingScore.hint"))

            Spacer()

            Text(loc.t("browse.passingScore.hint"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Toolbar

    private var browseToolbar: some View {
        HStack(spacing: 12) {
            Button {
                if viewModel.hasChanges { showDiscardAlert = true } else { dismiss() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(loc.t("general.back"))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)

            Divider().frame(height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.bank.metadata.certification)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(viewModel.bank.questions.count) \(loc.t("browse.questions"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.hasChanges {
                Label(loc.t("browse.unsavedChanges"), systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Picker(loc.t("browse.allDomains"), selection: $viewModel.filterDomain) {
                Text(loc.t("browse.allDomains")).tag(nil as String?)
                Divider()
                ForEach(viewModel.availableDomains, id: \.self) { d in
                    Text(d).tag(d as String?)
                }
            }
            .frame(width: 220)

            TextField(loc.t("browse.searchPlaceholder"), text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)

            if viewModel.hasChanges {
                Button {
                    Task { await viewModel.saveChanges() }
                } label: {
                    Label(loc.t("browse.save"), systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.filteredQuestions.isEmpty {
            emptyState
        } else {
            questionList
        }
    }

    private var questionList: some View {
        List(viewModel.filteredQuestions) { question in
            QuestionRowView(question: question, isModified: question != originalQuestion(question))
                .contentShape(Rectangle())
                .onTapGesture { editingQuestion = question }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(loc.t("browse.noResults"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func originalQuestion(_ q: Question) -> Question? {
        // Used only to flag visually modified rows; returns nil when bank was just saved
        nil
    }
}

// MARK: - QuestionRowView

private struct QuestionRowView: View {
    let question: Question
    var isModified: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(question.id)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)

            Text(question.domain)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 190, alignment: .leading)

            Text(question.question)
                .font(.subheadline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "pencil")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .leading) {
            if isModified {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange)
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - QuestionEditorSheet

struct QuestionEditorSheet: View {
    let onSave: (Question) -> Void
    let availableDomains: [String]

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationService
    @State private var draft: Question

    init(question: Question, availableDomains: [String], onSave: @escaping (Question) -> Void) {
        _draft = State(initialValue: question)
        self.availableDomains = availableDomains
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    metadataSection
                    questionTextSection
                    alternativesSection
                    explanationsSection
                    noteSection
                }
                .padding(28)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 720, minHeight: 580)
    }

    // MARK: Editor Toolbar

    private var editorToolbar: some View {
        HStack {
            Button(loc.t("general.cancel")) { dismiss() }
                .keyboardShortcut(.cancelAction)

            Spacer()

            VStack(spacing: 2) {
                Text(loc.t("editor.title"))
                    .font(.headline)
                Text("#\(draft.id) — \(draft.domain)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(loc.t("general.done")) {
                onSave(syncCorrectAnswer())
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Metadata

    private var metadataSection: some View {
        GroupBox(loc.t("editor.metadata")) {
            HStack(spacing: 12) {
                Text(loc.t("editor.domain"))
                    .font(.subheadline)
                    .frame(width: 90, alignment: .leading)

                TextField(loc.t("editor.domain"), text: $draft.domain)
                    .textFieldStyle(.roundedBorder)

                Menu {
                    ForEach(availableDomains, id: \.self) { d in
                        Button(d) { draft.domain = d }
                    }
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help(loc.t("editor.domainPicker"))
            }
            .padding(12)
        }
    }

    // MARK: Question Text

    private var questionTextSection: some View {
        GroupBox(loc.t("editor.questionText")) {
            TextEditor(text: $draft.question)
                .font(.body)
                .frame(minHeight: 80, maxHeight: 200)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(4)
        }
    }

    // MARK: Alternatives

    private var alternativesSection: some View {
        GroupBox(loc.t("editor.alternatives")) {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Text(loc.t("editor.correctAnswerHint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(draft.alternatives.indices, id: \.self) { idx in
                    HStack(spacing: 10) {
                        let isCorrect = draft.alternatives[idx].letter == draft.correctAnswer

                        Button {
                            draft.correctAnswer = draft.alternatives[idx].letter
                        } label: {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isCorrect ? .green : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .help(loc.t("editor.correctAnswer"))

                        Text(draft.alternatives[idx].letter)
                            .font(.subheadline.weight(.bold))
                            .frame(width: 26, alignment: .center)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(isCorrect
                                ? Color.green.opacity(0.15)
                                : Color(nsColor: .controlColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        TextField("", text: $draft.alternatives[idx].text)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: Explanations

    private var explanationsSection: some View {
        GroupBox(loc.t("editor.explanations")) {
            VStack(alignment: .leading, spacing: 16) {
                explanationField(
                    label: loc.t("editor.explanationEn"),
                    text: $draft.explanationEn
                )
                Divider()
                explanationField(
                    label: loc.t("editor.explanationPtBr"),
                    text: $draft.explanationPtBr
                )
            }
            .padding(12)
        }
    }

    private func explanationField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.body)
                .frame(minHeight: 80, maxHeight: 160)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: Note

    private var noteSection: some View {
        GroupBox(loc.t("editor.note")) {
            TextField(loc.t("editor.notePlaceholder"), text: $draft.note)
                .textFieldStyle(.roundedBorder)
                .padding(8)
        }
    }

    // MARK: Helpers

    /// Syncs `isCorrect` flags on each alternative to match `correctAnswer`.
    private func syncCorrectAnswer() -> Question {
        let synced = draft.alternatives.map { alt in
            Alternative(letter: alt.letter, text: alt.text, isCorrect: alt.letter == draft.correctAnswer)
        }
        return Question(
            id: draft.id,
            domain: draft.domain,
            question: draft.question,
            alternatives: synced,
            correctAnswer: draft.correctAnswer,
            explanationEn: draft.explanationEn,
            explanationPtBr: draft.explanationPtBr,
            note: draft.note
        )
    }
}
