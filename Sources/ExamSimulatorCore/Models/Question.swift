import Foundation

public struct Question: Codable, Identifiable, Hashable {
    public let id: Int
    public let simulado: Int
    public let domain: String
    public let question: String
    public let alternatives: [Alternative]
    public let correctAnswer: String
    public let explanationEn: String
    public let explanationPtBr: String
    public let note: String

    enum CodingKeys: String, CodingKey {
        case id, simulado, domain, question, alternatives
        case correctAnswer = "correct_answer"
        case explanationEn = "explanation_en"
        case explanationPtBr = "explanation_ptbr"
        case note
    }

    public func explanation(for language: String) -> String {
        switch language.lowercased() {
        case "pt-br": return explanationPtBr.isEmpty ? explanationEn : explanationPtBr
        default: return explanationEn
        }
    }
}

public struct Alternative: Codable, Identifiable, Hashable {
    public var id: String { letter }
    public let letter: String
    public let text: String
    public let isCorrect: Bool

    enum CodingKeys: String, CodingKey {
        case letter, text
        case isCorrect = "is_correct"
    }
}
