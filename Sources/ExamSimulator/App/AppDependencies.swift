import Foundation
import ExamSimulatorCore

@MainActor
final class AppDependencies: ObservableObject {
    let configService: AppConfigService
    let localization: LocalizationService
    let bankRepository: ExamBankRepository
    let progressRepository: ProgressRepository
    let aiService: AIStudyAssistantService
    let engine: ExamEngine

    /// Observable proxy — set to `true` whenever a valid API key is stored.
    @Published var isAIAvailable: Bool = false

    // UserDefaults key for the OpenAI API key.
    static let apiKeyDefaultsKey = "com.examsimulator.openai.apikey"

    init() {
        let bundle = Bundle.module
        configService  = AppConfigService(bundle: bundle)
        localization   = LocalizationService(config: configService.config, bundle: bundle)
        bankRepository = ExamBankRepository(bundle: bundle)
        progressRepository = ProgressRepository(storageConfig: configService.config.storage)
        engine = ExamEngine()

        // OpenAIProvider reads the key via closure, so UserDefaults changes
        // are always reflected without re-creating the service.
        aiService = AIStudyAssistantService(
            provider: OpenAIProvider(
                config: configService.config.aiProvider,
                apiKeyResolver: {
                    UserDefaults.standard.string(forKey: AppDependencies.apiKeyDefaultsKey) ?? ""
                }
            )
        )

        let stored = UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey) ?? ""
        isAIAvailable = !stored.isEmpty
    }

    var config: AppConfig { configService.config }

    // MARK: - API Key management

    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: Self.apiKeyDefaultsKey)
        isAIAvailable = !trimmed.isEmpty
    }

    func loadAPIKey() -> String {
        UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey) ?? ""
    }

    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: Self.apiKeyDefaultsKey)
        isAIAvailable = false
    }
}
