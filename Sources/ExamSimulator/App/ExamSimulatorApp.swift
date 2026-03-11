import SwiftUI
import AppKit
import ExamSimulatorCore

// AppDelegate handles proper keyboard focus acquisition when launched via `swift run`.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // SPM executables start with activationPolicy = .prohibited (no GUI focus).
        // Setting .regular ensures the window server routes keyboard events to this process.
        NSApp.setActivationPolicy(.regular)

        // Set app icon from the bundled PNG resource.
        // This is required for SPM executables launched via `swift run` since
        // they don't go through the standard .app bundle icon resolution path.
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = image
        }

        // Wait for the first window to actually become key before requesting focus.
        // This is more reliable than a fixed-delay asyncAfter because we react to the real event.
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let win = note.object as? NSWindow else { return }
            NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
            win.makeKeyAndOrderFront(nil)
            if let obs = self?.windowObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.windowObserver = nil
            }
        }
    }
}

@main
struct ExamSimulatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
