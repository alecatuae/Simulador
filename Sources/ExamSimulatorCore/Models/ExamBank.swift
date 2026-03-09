import Foundation

public struct ExamBank: Codable, Identifiable, Hashable {
    public var id: String { metadata.certification }
    public let metadata: ExamBankMetadata
    public var questions: [Question]   // var — editable via Browse Questions

    public var bankId: String { metadata.certification }

    public init(metadata: ExamBankMetadata, questions: [Question]) {
        self.metadata = metadata
        self.questions = questions
    }
}

public struct ExamBankMetadata: Codable, Hashable {
    public let title: String
    public let certification: String
    public let source: String
    public let format: String
    public let totalQuestions: Int
    public let simulados: [SimuladoInfo]
    public let domains: [DomainInfo]

    enum CodingKeys: String, CodingKey {
        case title, certification, source, format
        case totalQuestions = "total_questions"
        case simulados, domains
    }
}

public struct SimuladoInfo: Codable, Identifiable, Hashable {
    public var id: Int { number }
    public let number: Int
    public let range: String
    public let questions: Int
}

public struct DomainInfo: Codable, Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let count: Int
}
