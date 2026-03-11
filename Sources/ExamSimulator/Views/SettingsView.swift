import SwiftUI
import ExamSimulatorCore

struct SettingsView: View {
    @EnvironmentObject var deps: AppDependencies
    @EnvironmentObject var loc: LocalizationService

    @State private var apiKey: String = ""
    @State private var isTesting = false
    @State private var testResult: TestResult? = nil
    @State private var showKey = false

    enum TestResult {
        case success(String)
        case failure(String)
    }

    var body: some View {
        TabView {
            aiTab
                .tabItem {
                    Label(loc.t("settings.ai.tab"), systemImage: "sparkles")
                }
        }
        .frame(width: 480, height: 340)
        .onAppear { apiKey = deps.loadAPIKey() }
    }

    // MARK: - AI Tab

    private var aiTab: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.t("settings.ai.title"))
                            .font(.headline)
                        Text(loc.t("settings.ai.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 4)
            }

            Section(loc.t("settings.ai.apiKey")) {
                HStack {
                    if showKey {
                        TextField(loc.t("settings.ai.apiKey.placeholder"), text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField(loc.t("settings.ai.apiKey.placeholder"), text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button(loc.t("settings.ai.save")) {
                        deps.saveAPIKey(apiKey)
                        testResult = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(loc.t("settings.ai.test")) {
                        Task { await testConnection() }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                    if isTesting {
                        ProgressView().scaleEffect(0.8)
                    }

                    if !apiKey.isEmpty {
                        Button(loc.t("settings.ai.clear")) {
                            apiKey = ""
                            deps.clearAPIKey()
                            testResult = nil
                        }
                        .foregroundStyle(.red)
                    }

                    Spacer()
                }

                if let result = testResult {
                    testResultBanner(result)
                }
            }

            Section(loc.t("settings.ai.status")) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(deps.isAIAvailable ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(deps.isAIAvailable
                         ? loc.t("settings.ai.status.enabled")
                         : loc.t("settings.ai.status.disabled"))
                        .font(.subheadline)
                        .foregroundStyle(deps.isAIAvailable ? .primary : .secondary)

                    Spacer()

                    if deps.isAIAvailable {
                        Text(deps.config.aiProvider.model)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func testResultBanner(_ result: TestResult) -> some View {
        HStack(spacing: 8) {
            switch result {
            case .success(let msg):
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text(msg).font(.caption).foregroundStyle(.green)
            case .failure(let msg):
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                Text(msg).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Test connection

    private func testConnection() async {
        isTesting = true
        testResult = nil

        // Save the key temporarily to let the provider use it
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        deps.saveAPIKey(trimmed)

        do {
            let response = try await deps.aiService.simplify(
                explanation: "Test: AI integration is working correctly."
            )
            testResult = .success("\(loc.t("settings.ai.test.success")): \(response.prefix(60))…")
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            testResult = .failure(msg)
        }
        isTesting = false
    }
}
