import Foundation

public struct UserProgress: Codable {
    public var sessions: [SessionResult]
    public var bookmarks: Set<Int>
    public var userNotes: [String: String]
    public var incorrectHistory: Set<Int>
    public var totalStudyTime: TimeInterval

    public init() {
        sessions = []
        bookmarks = []
        userNotes = [:]
        incorrectHistory = []
        totalStudyTime = 0
    }

    public func lastSession(for bankId: String? = nil) -> SessionResult? {
        let filtered = bankId.map { id in sessions.filter { $0.bankId == id } } ?? sessions
        return filtered.sorted { $0.date > $1.date }.first
    }

    public func averageScore(for bankId: String? = nil) -> Double? {
        let filtered = bankId.map { id in sessions.filter { $0.bankId == id } } ?? sessions
        guard !filtered.isEmpty else { return nil }
        return filtered.map { $0.scorePercentage }.reduce(0, +) / Double(filtered.count)
    }

    public mutating func addSession(_ result: SessionResult) {
        sessions.append(result)
        totalStudyTime += result.elapsedTime

        let newIncorrectIds = result.questionResults
            .filter { !$0.isCorrect }
            .map { $0.questionId }
        incorrectHistory.formUnion(newIncorrectIds)

        let newCorrectIds = result.questionResults
            .filter { $0.isCorrect }
            .map { $0.questionId }
        incorrectHistory.subtract(newCorrectIds)
    }

    public mutating func toggleBookmark(questionId: Int) {
        if bookmarks.contains(questionId) {
            bookmarks.remove(questionId)
        } else {
            bookmarks.insert(questionId)
        }
    }

    public func noteKey(bankId: String, questionId: Int) -> String {
        "\(bankId):\(questionId)"
    }

    public mutating func setNote(_ text: String, bankId: String, questionId: Int) {
        let key = noteKey(bankId: bankId, questionId: questionId)
        if text.isEmpty {
            userNotes.removeValue(forKey: key)
        } else {
            userNotes[key] = text
        }
    }

    public func note(bankId: String, questionId: Int) -> String? {
        userNotes[noteKey(bankId: bankId, questionId: questionId)]
    }
}
