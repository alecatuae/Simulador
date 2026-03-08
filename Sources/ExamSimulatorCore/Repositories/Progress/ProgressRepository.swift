import Foundation

public final class ProgressRepository {
    private let storageURL: URL
    private let filename = "progress.json"

    private var fileURL: URL {
        storageURL.appendingPathComponent(filename)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public init(storageConfig: StorageConfig) {
        self.storageURL = storageConfig.resolvedProgressDirectory
    }

    public init(directory: URL) {
        self.storageURL = directory
    }

    public func load() throws -> UserProgress {
        ensureDirectoryExists()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return UserProgress()
        }
        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode(UserProgress.self, from: data)
    }

    public func save(_ progress: UserProgress) throws {
        ensureDirectoryExists()
        let data = try Self.encoder.encode(progress)
        try data.write(to: fileURL, options: .atomic)
    }

    public func addSession(_ result: SessionResult) throws {
        var progress = (try? load()) ?? UserProgress()
        progress.addSession(result)
        try save(progress)
    }

    public func reset() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(
            at: storageURL,
            withIntermediateDirectories: true
        )
    }
}
