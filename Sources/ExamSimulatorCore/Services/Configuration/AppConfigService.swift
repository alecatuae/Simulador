import Foundation

public final class AppConfigService {
    public private(set) var config: AppConfig

    public init(bundle: Bundle) {
        self.config = (try? AppConfigService.load(from: bundle)) ?? AppConfig.fallback
    }

    private static func load(from bundle: Bundle) throws -> AppConfig {
        guard let url = bundle.url(forResource: "AppConfig", withExtension: "json") else {
            throw ConfigError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppConfig.self, from: data)
    }
}

public enum ConfigError: LocalizedError {
    case fileNotFound
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound: return "AppConfig.json not found in bundle"
        case .decodingFailed(let msg): return "Failed to decode AppConfig.json: \(msg)"
        }
    }
}
