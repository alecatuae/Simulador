import SwiftUI
import ExamSimulatorCore

@main
struct ExamSimulatorApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .environmentObject(dependencies.localization)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Exam Simulator") {}
            }
        }

        Settings {
            SettingsView()
                .environmentObject(dependencies)
                .environmentObject(dependencies.localization)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var deps: AppDependencies
    @StateObject private var dashboardVM: DashboardViewModel

    init() {
        _dashboardVM = StateObject(wrappedValue: DashboardViewModel())
    }

    var body: some View {
        DashboardView(viewModel: dashboardVM)
            .onAppear {
                dashboardVM.configure(
                    bankRepo: deps.bankRepository,
                    progressRepo: deps.progressRepository,
                    config: deps.config,
                    engine: deps.engine
                )
                dashboardVM.loadData()
            }
            .frame(minWidth: 900, minHeight: 600)
    }
}
