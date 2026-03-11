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

    private let aiService: AIStudyAssistantService

    init(aiService: AIStudyAssistantService, question: Question, selectedAnswer: String?) {
        self.aiService = aiService
        self.question = question
        self.selectedAnswer = selectedAnswer
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
                selectedAnswer: selectedAnswer
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
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)

        isLoading = true
        error = nil
        do {
            // Send only user/assistant messages (no system messages in history)
            let history = messages.filter { $0.role != .system }
            let response = try await aiService.chat(messages: history, question: question)
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            self.error = errorMessage(from: error)
        }
        isLoading = false
    }

    func dismissError() { error = nil }

    // MARK: - Private

    private func errorMessage(from error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
