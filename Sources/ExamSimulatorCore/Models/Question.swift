import Foundation

public struct Question: Codable, Identifiable, Hashable {
    public let id: Int           // immutable — unique key
    public var simulado: Int
    public var domain: String
    public var question: String
    public var alternatives: [Alternative]
    public var correctAnswer: String
    public var explanationEn: String
    public var explanationPtBr: String
    public var note: String

    public init(
        id: Int,
        simulado: Int,
        domain: String,
        question: String,
        alternatives: [Alternative],
        correctAnswer: String,
        explanationEn: String,
        explanationPtBr: String,
        note: String
    ) {
        self.id = id
        self.simulado = simulado
        self.domain = domain
        self.question = question
        self.alternatives = alternatives
        self.correctAnswer = correctAnswer
        self.explanationEn = explanationEn
        self.explanationPtBr = explanationPtBr
        self.note = note
    }

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
    public let letter: String    // immutable — unique key within a question
    public var text: String
    public var isCorrect: Bool

    public init(letter: String, text: String, isCorrect: Bool) {
        self.letter = letter
        self.text = text
        self.isCorrect = isCorrect
    }

    enum CodingKeys: String, CodingKey {
        case letter, text
        case isCorrect = "is_correct"
    }
}
