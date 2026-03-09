import Foundation

public final class ExamBankRepository {
    private let bundle: Bundle
    private var cache: [String: ExamBank] = [:]
    /// Maps bankId (certification) → original bundle filename (no extension).
    private var filenameForBank: [String: String] = [:]

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    // MARK: - Load

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

        return try jsonFiles.compactMap { bundleURL -> ExamBank? in
            let filename = bundleURL.deletingPathExtension().lastPathComponent

            // Prefer an App Support override if present
            let overrideURL = appSupportQAsDir.appendingPathComponent(bundleURL.lastPathComponent)
            let effectiveURL = FileManager.default.fileExists(atPath: overrideURL.path)
                ? overrideURL : bundleURL

            // Use cache only for the bundle version (overrides may be fresher)
            if effectiveURL == bundleURL, let cached = cache[filename] {
                return cached
            }

            let bank = try load(from: effectiveURL)
            cache[filename] = bank
            filenameForBank[bank.bankId] = filename
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
        filenameForBank[bank.bankId] = filename
        return bank
    }

    // MARK: - Save

    /// Persists a modified bank to Application Support so edits survive app restarts.
    /// The repository cache is updated immediately; the next `loadAll()` will prefer
    /// the saved version over the original bundle file.
    public func save(_ bank: ExamBank) throws {
        guard let filename = filenameForBank[bank.bankId] else {
            throw ExamBankError.fileNotFound(bank.bankId)
        }

        let dir = appSupportQAsDir
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)

        let url = dir.appendingPathComponent("\(filename).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(bank)
        try data.write(to: url, options: .atomic)

        // Refresh cache with the saved version
        cache[filename] = bank
    }

    // MARK: - Cache

    public func clearCache() {
        cache.removeAll()
        filenameForBank.removeAll()
    }

    // MARK: - Private helpers

    private var appSupportQAsDir: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExamSimulator/QAs", isDirectory: true)
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
                throw ExamBankError.invalidQuestion(
                    question.id,
                    "correct_answer '\(question.correctAnswer)' not found in alternatives"
                )
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
