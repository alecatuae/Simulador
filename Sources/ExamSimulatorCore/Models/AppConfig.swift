import Foundation

public struct AppConfig: Codable {
    public let appVersion: String
    public let defaultLanguage: String
    public let fallbackLanguage: String
    public let examDefaults: ExamDefaults
    public let aiProvider: AIProviderConfig
    public let features: FeatureFlags
    public let storage: StorageConfig

    public static var fallback: AppConfig {
        AppConfig(
            appVersion: "1.0.0",
            defaultLanguage: "en-us",
            fallbackLanguage: "en-us",
            examDefaults: .default,
            aiProvider: .default,
            features: .default,
            storage: .default
        )
    }
}

public struct ExamDefaults: Codable {
    public let timerMinutes: Int
    public let passingScorePercent: Double
    public let randomizeQuestions: Bool
    public let randomizeAnswers: Bool

    public var timerSeconds: TimeInterval { Double(timerMinutes) * 60 }

    public static var `default`: ExamDefaults {
        ExamDefaults(timerMinutes: 90, passingScorePercent: 70.0,
                     randomizeQuestions: true, randomizeAnswers: false)
    }
}

public struct AIProviderConfig: Codable {
    public let enabled: Bool
    public let provider: String
    public let baseURL: String
    public let model: String
    public let apiKeyEnvVar: String

    public static var `default`: AIProviderConfig {
        AIProviderConfig(enabled: false, provider: "openai",
                         baseURL: "https://api.openai.com/v1",
                         model: "gpt-4o-mini", apiKeyEnvVar: "OPENAI_API_KEY")
    }
}

public struct FeatureFlags: Codable {
    public let studyMode: Bool
    public let examMode: Bool
    public let reviewMode: Bool
    public let progressTracking: Bool
    public let aiAssistant: Bool
    public let bookmarks: Bool

    public static var `default`: FeatureFlags {
        FeatureFlags(studyMode: true, examMode: true, reviewMode: true,
                     progressTracking: true, aiAssistant: false, bookmarks: true)
    }
}

public struct StorageConfig: Codable {
    public let progressDirectory: String

    public var resolvedProgressDirectory: URL {
        let path = progressDirectory.replacingOccurrences(of: "~", with: NSHomeDirectory())
        return URL(fileURLWithPath: path)
    }

    public static var `default`: StorageConfig {
        StorageConfig(progressDirectory: "~/Library/Application Support/ExamSimulator")
    }
}
