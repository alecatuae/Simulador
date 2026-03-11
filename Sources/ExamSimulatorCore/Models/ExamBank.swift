import Foundation

public struct ExamBank: Codable, Identifiable, Hashable {
    public var id: String { metadata.certification }
    public var metadata: ExamBankMetadata   // var — passingScorePercent editable via Browse Questions
    public var questions: [Question]        // var — editable via Browse Questions

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
    public let domains: [DomainInfo]
    /// Minimum passing score (0–100). Defaults to 70.0 if absent in JSON.
    public var passingScorePercent: Double

    enum CodingKeys: String, CodingKey {
        case title, certification, source, format
        case totalQuestions = "total_questions"
        case domains
        case passingScorePercent = "passing_score_percent"
    }

    // Custom decoder so legacy JSON files without `passing_score_percent` use 70.0.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title               = try c.decode(String.self,         forKey: .title)
        certification       = try c.decode(String.self,         forKey: .certification)
        source              = try c.decode(String.self,         forKey: .source)
        format              = try c.decode(String.self,         forKey: .format)
        totalQuestions      = try c.decode(Int.self,            forKey: .totalQuestions)
        domains             = try c.decode([DomainInfo].self,   forKey: .domains)
        passingScorePercent = try c.decodeIfPresent(Double.self, forKey: .passingScorePercent) ?? 70.0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title,               forKey: .title)
        try c.encode(certification,       forKey: .certification)
        try c.encode(source,              forKey: .source)
        try c.encode(format,              forKey: .format)
        try c.encode(totalQuestions,      forKey: .totalQuestions)
        try c.encode(domains,             forKey: .domains)
        try c.encode(passingScorePercent, forKey: .passingScorePercent)
    }
}

public struct DomainInfo: Codable, Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let count: Int
}
