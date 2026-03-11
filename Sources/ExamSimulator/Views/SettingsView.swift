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
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.purple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.t("settings.ai.title"))
                        .font(.headline)
                    Text(loc.t("settings.ai.description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                statusBadge
            }
            .padding(20)

            Divider()

            // API Key section
            VStack(alignment: .leading, spacing: 12) {
                Text(loc.t("settings.ai.apiKey"))
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 8) {
                    Group {
                        if showKey {
                            TextField(loc.t("settings.ai.apiKey.placeholder"), text: $apiKey)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField(loc.t("settings.ai.apiKey.placeholder"), text: $apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .frame(width: 20)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help(showKey ? "Hide key" : "Show key")
                }

                HStack(spacing: 10) {
                    Button(loc.t("settings.ai.save")) {
                        saveKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(loc.t("settings.ai.test")) {
                        Task { await testConnection() }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                    if isTesting {
                        ProgressView().scaleEffect(0.8).frame(width: 20, height: 20)
                    }

                    Spacer()

                    if !apiKey.isEmpty {
                        Button(loc.t("settings.ai.clear")) {
                            apiKey = ""
                            deps.clearAPIKey()
                            testResult = nil
                        }
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                    }
                }

                if let result = testResult {
                    testResultBanner(result)
                }
            }
            .padding(20)

            Divider()

            // Model info footer
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(loc.t("settings.ai.status"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                Text(deps.config.aiProvider.model)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 480)
        .onAppear { apiKey = deps.loadAPIKey() }
    }

    // MARK: - Status badge

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(deps.isAIAvailable ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(deps.isAIAvailable
                 ? loc.t("settings.ai.status.enabled")
                 : loc.t("settings.ai.status.disabled"))
                .font(.caption.weight(.medium))
                .foregroundStyle(deps.isAIAvailable ? .green : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(deps.isAIAvailable ? Color.green.opacity(0.08) : Color(nsColor: .controlColor))
        .clipShape(Capsule())
    }

    // MARK: - Test result

    private func testResultBanner(_ result: TestResult) -> some View {
        HStack(spacing: 8) {
            switch result {
            case .success(let msg):
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text(msg).font(.caption).foregroundStyle(.primary).lineLimit(3)
            case .failure(let msg):
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                Text(msg).font(.caption).foregroundStyle(.primary).lineLimit(3)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (testResult.map { if case .success = $0 { return true }; return false } ?? false)
                ? Color.green.opacity(0.08) : Color.red.opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func saveKey() {
        deps.saveAPIKey(apiKey)
        testResult = nil
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil
        // Persist the key first so the provider can use it
        deps.saveAPIKey(apiKey)
        do {
            let response = try await deps.aiService.simplify(
                explanation: "The AI assistant is working correctly."
            )
            let preview = String(response.prefix(80))
            testResult = .success("\(loc.t("settings.ai.test.success")): \(preview)…")
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            testResult = .failure(msg)
        }
        isTesting = false
    }
}
