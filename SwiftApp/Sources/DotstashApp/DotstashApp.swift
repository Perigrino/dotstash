import SwiftUI
import Sparkle

@main
struct DotstashApp: App {
    @StateObject private var manager = DotstashManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Auto-update controller
    @StateObject private var updaterController = UpdaterController()
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .environmentObject(updaterController)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    appDelegate.setupStatusBar(warningCount: manager.warningCount)
                }
                .onChange(of: manager.warningCount) { _, newValue in
                    appDelegate.updateBadge(warningCount: newValue)
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 650)
        
        // Menu bar icon
        MenuBarExtra {
            MenuBarView()
                .environmentObject(manager)
                .environmentObject(updaterController)
        } label: {
            Label {
                Text("Dotstash")
            } icon: {
                Image(systemName: manager.warningCount > 0 ? "tray.full.fill" : "tray.full")
            }
        }
        .menuBarExtraStyle(.window)
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(updaterController)
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    
    nonisolated func setupStatusBar(warningCount: Int) {
        Task { @MainActor in
            statusBarController.setup()
            statusBarController.updateBadge(warningCount: warningCount)
        }
    }
    
    nonisolated func updateBadge(warningCount: Int) {
        Task { @MainActor in
            statusBarController.updateBadge(warningCount: warningCount)
        }
    }
}
