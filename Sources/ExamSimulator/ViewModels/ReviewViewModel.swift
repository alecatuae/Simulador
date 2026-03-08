import Foundation
import ExamSimulatorCore

@MainActor
final class ReviewViewModel: ObservableObject {
    enum ReviewFilter: String, CaseIterable, Identifiable {
        case all = "review.filter.all"
        case correct = "review.filter.correct"
        case incorrect = "review.filter.incorrect"
        case flagged = "review.filter.flagged"

        var id: String { rawValue }
    }

    @Published var selectedFilter: ReviewFilter = .all
    @Published var currentIndex: Int = 0

    let result: SessionResult
    let bank: ExamBank

    private let questionsById: [Int: Question]

    init(result: SessionResult, bank: ExamBank) {
        self.result = result
        self.bank = bank
        self.questionsById = Dictionary(uniqueKeysWithValues: bank.questions.map { ($0.id, $0) })
    }

    var filteredResults: [QuestionResult] {
        let all = result.questionResults
        switch selectedFilter {
        case .all:      return all
        case .correct:  return all.filter { $0.isCorrect }
        case .incorrect: return all.filter { !$0.isCorrect }
        case .flagged:  return all.filter { $0.wasFlagged }
        }
    }

    var currentResult: QuestionResult? {
        guard currentIndex < filteredResults.count else { return nil }
        return filteredResults[currentIndex]
    }

    var currentQuestion: Question? {
        guard let r = currentResult else { return nil }
        return questionsById[r.questionId]
    }

    var totalFiltered: Int { filteredResults.count }
    var isFirstItem: Bool { currentIndex == 0 }
    var isLastItem: Bool { currentIndex == filteredResults.count - 1 }

    func next() { if !isLastItem { currentIndex += 1 } }
    func previous() { if !isFirstItem { currentIndex -= 1 } }

    func navigate(to index: Int) {
        guard index >= 0 && index < filteredResults.count else { return }
        currentIndex = index
    }

    func onFilterChange() {
        currentIndex = 0
    }
}
