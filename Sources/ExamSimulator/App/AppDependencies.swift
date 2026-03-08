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

    init() {
        let bundle = Bundle.module
        configService = AppConfigService(bundle: bundle)
        localization = LocalizationService(config: configService.config, bundle: bundle)
        bankRepository = ExamBankRepository(bundle: bundle)
        progressRepository = ProgressRepository(storageConfig: configService.config.storage)
        aiService = AIStudyAssistantService(provider: MockAIProvider())
        engine = ExamEngine()
    }

    var config: AppConfig { configService.config }
}
