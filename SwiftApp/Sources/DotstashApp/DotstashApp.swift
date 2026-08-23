import SwiftUI
import Sparkle

@main
struct DotstashApp: App {
    @StateObject private var manager = DotstashManager()
    
    // Auto-update controller
    @StateObject private var updaterController = UpdaterController()
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .environmentObject(updaterController)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 650)
        
        // Menu bar icon with popover menu
        MenuBarExtra {
            MenuBarView()
                .environmentObject(manager)
                .environmentObject(updaterController)
        } label: {
            // Show badge count in menu bar if there are warnings
            if manager.warningCount > 0 {
                Label {
                    Text("Dotstash")
                } icon: {
                    HStack(spacing: 2) {
                        Image(systemName: "tray.full.fill")
                        Text("\(manager.warningCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                }
            } else {
                Label {
                    Text("Dotstash")
                } icon: {
                    Image(systemName: "tray.full")
                }
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
