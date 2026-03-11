import Foundation
import ExamSimulatorCore

@MainActor
final class AIAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    @Published var error: String?

    let question: Question
    let selectedAnswer: String?
    let languageIsEnglish: Bool

    private let aiService: AIStudyAssistantService

    var language: String { languageIsEnglish ? "en" : "pt-BR" }

    init(aiService: AIStudyAssistantService,
         question: Question,
         selectedAnswer: String?,
         languageIsEnglish: Bool = true) {
        self.aiService = aiService
        self.question = question
        self.selectedAnswer = selectedAnswer
        self.languageIsEnglish = languageIsEnglish
    }

    // MARK: - Actions

    /// Called the first time the panel is shown — fetches the initial AI explanation.
    func loadInitialExplanation() async {
        guard messages.isEmpty, !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let response = try await aiService.explain(
                question: question,
                selectedAnswer: selectedAnswer,
                language: language
            )
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            self.error = errorMessage(from: error)
        }
        isLoading = false
    }

    /// Send the current `inputText` as a follow-up question.
    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        inputText = ""
        await sendMessage(text)
    }

    /// Send a predefined suggestion prompt directly.
    func quickSend(_ prompt: String) {
        guard !isLoading else { return }
        inputText = ""
        Task { await sendMessage(prompt) }
    }

    func dismissError() { error = nil }

    // MARK: - Private

    private func sendMessage(_ text: String) async {
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)

        isLoading = true
        error = nil
        do {
            let history = messages.filter { $0.role != .system }
            let response = try await aiService.chat(
                messages: history,
                question: question,
                language: language
            )
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            self.error = errorMessage(from: error)
        }
        isLoading = false
    }

    private func errorMessage(from error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
