import Foundation
import ExamSimulatorCore

@MainActor
final class BrowseQuestionsViewModel: ObservableObject {
    @Published var bank: ExamBank
    @Published var searchText: String = ""
    @Published var filterDomain: String? = nil
    @Published var isSaving = false
    @Published var saveError: String?

    private var originalBank: ExamBank
    private let repository: ExamBankRepository

    init(bank: ExamBank, repository: ExamBankRepository) {
        self.bank = bank
        self.originalBank = bank
        self.repository = repository
    }

    // MARK: - Derived

    var filteredQuestions: [Question] {
        var qs = bank.questions
        if let domain = filterDomain {
            qs = qs.filter { $0.domain == domain }
        }
        if !searchText.isEmpty {
            let term = searchText.lowercased()
            qs = qs.filter {
                $0.question.lowercased().contains(term) ||
                $0.domain.lowercased().contains(term) ||
                "\($0.id)".contains(searchText)
            }
        }
        return qs
    }

    var availableDomains: [String] {
        Array(Set(bank.questions.map(\.domain))).sorted()
    }

    var hasChanges: Bool { bank.questions != originalBank.questions }

    // MARK: - Mutations

    func update(_ question: Question) {
        guard let idx = bank.questions.firstIndex(where: { $0.id == question.id }) else { return }
        bank.questions[idx] = question
    }

    func discardChanges() {
        bank = originalBank
        searchText = ""
        filterDomain = nil
    }

    // MARK: - Persistence

    func saveChanges() async {
        isSaving = true
        saveError = nil
        do {
            try repository.save(bank)
            originalBank = bank
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}
