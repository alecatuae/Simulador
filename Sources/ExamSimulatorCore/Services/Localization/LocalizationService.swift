import Foundation

public final class LocalizationService: ObservableObject {
    @Published public private(set) var currentLanguage: String

    private var strings: [String: String] = [:]
    private let fallbackLanguage: String
    private let bundle: Bundle

    private static let userDefaultsKey = "app.language"

    public init(config: AppConfig, bundle: Bundle) {
        let saved = UserDefaults.standard.string(forKey: Self.userDefaultsKey)
        let language = saved ?? config.defaultLanguage
        self.currentLanguage = language
        self.fallbackLanguage = config.fallbackLanguage
        self.bundle = bundle
        loadLanguage(language)
    }

    public func t(_ key: String) -> String {
        strings[key] ?? key
    }

    public func t(_ key: String, _ args: CVarArg...) -> String {
        let template = strings[key] ?? key
        return String(format: template, arguments: args)
    }

    public func switchLanguage(to language: String) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: Self.userDefaultsKey)
        loadLanguage(language)
    }

    public func availableLanguages(in bundle: Bundle) -> [LanguagePack] {
        guard let langDir = bundle.resourceURL?.appendingPathComponent("Languages") else { return [] }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: langDir, includingPropertiesForKeys: nil
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> LanguagePack? in
                guard let data = try? Data(contentsOf: url),
                      let pack = try? JSONDecoder().decode(LanguagePackFile.self, from: data)
                else { return nil }
                return LanguagePack(code: pack.language, name: pack.name)
            }
            .sorted { $0.name < $1.name }
    }

    private func loadLanguage(_ language: String) {
        if let loaded = loadStrings(for: language) {
            strings = loaded
            return
        }
        if language != fallbackLanguage, let fallback = loadStrings(for: fallbackLanguage) {
            strings = fallback
        }
    }

    private func loadStrings(for language: String) -> [String: String]? {
        guard let url = bundle.url(forResource: language, withExtension: "json", subdirectory: "Languages"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(LanguagePackFile.self, from: data)
        else { return nil }
        return pack.keys
    }
}

public struct LanguagePack: Identifiable {
    public var id: String { code }
    public let code: String
    public let name: String
}

private struct LanguagePackFile: Decodable {
    let language: String
    let name: String
    let keys: [String: String]
}
