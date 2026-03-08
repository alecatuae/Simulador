import Foundation

public final class ExamBankRepository {
    private let bundle: Bundle
    private var cache: [String: ExamBank] = [:]

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public func loadAll() throws -> [ExamBank] {
        guard let qaDir = bundle.resourceURL?.appendingPathComponent("QAs") else {
            throw ExamBankError.directoryNotFound
        }

        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(
                at: qaDir,
                includingPropertiesForKeys: nil
            )
        } catch {
            throw ExamBankError.directoryNotFound
        }

        let jsonFiles = files.filter { $0.pathExtension == "json" }
        guard !jsonFiles.isEmpty else {
            throw ExamBankError.noExamsFound
        }

        return try jsonFiles.compactMap { url -> ExamBank? in
            let filename = url.deletingPathExtension().lastPathComponent
            if let cached = cache[filename] { return cached }
            let bank = try load(from: url)
            cache[filename] = bank
            return bank
        }.sorted { $0.metadata.certification < $1.metadata.certification }
    }

    public func load(named filename: String) throws -> ExamBank {
        if let cached = cache[filename] { return cached }

        guard let url = bundle.url(forResource: filename, withExtension: "json", subdirectory: "QAs") else {
            throw ExamBankError.fileNotFound(filename)
        }

        let bank = try load(from: url)
        cache[filename] = bank
        return bank
    }

    public func clearCache() {
        cache.removeAll()
    }

    private func load(from url: URL) throws -> ExamBank {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ExamBankError.fileNotFound(url.lastPathComponent)
        }

        let decoder = JSONDecoder()
        do {
            let bank = try decoder.decode(ExamBank.self, from: data)
            try validate(bank)
            return bank
        } catch let error as ExamBankError {
            throw error
        } catch {
            throw ExamBankError.decodingFailed(url.lastPathComponent, error.localizedDescription)
        }
    }

    private func validate(_ bank: ExamBank) throws {
        guard !bank.questions.isEmpty else {
            throw ExamBankError.emptyBank(bank.metadata.certification)
        }
        for question in bank.questions {
            guard question.alternatives.contains(where: { $0.letter == question.correctAnswer }) else {
                throw ExamBankError.invalidQuestion(question.id, "correct_answer '\(question.correctAnswer)' not found in alternatives")
            }
        }
    }
}

public enum ExamBankError: LocalizedError {
    case directoryNotFound
    case noExamsFound
    case fileNotFound(String)
    case decodingFailed(String, String)
    case emptyBank(String)
    case invalidQuestion(Int, String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound: return "QAs directory not found in bundle"
        case .noExamsFound: return "No JSON exam files found in Resources/QAs/"
        case .fileNotFound(let name): return "Exam bank file not found: \(name)"
        case .decodingFailed(let name, let msg): return "Failed to decode \(name): \(msg)"
        case .emptyBank(let name): return "Exam bank '\(name)' has no questions"
        case .invalidQuestion(let id, let msg): return "Invalid question #\(id): \(msg)"
        }
    }
}
