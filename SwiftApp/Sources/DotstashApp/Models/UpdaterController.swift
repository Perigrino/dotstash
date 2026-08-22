import Foundation
import Sparkle

// MARK: - Updater Controller

/// Wrapper around Sparkle's SPUUpdater for auto-updates.
/// Provides a simple interface for the SwiftUI app.
@MainActor
class UpdaterController: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    @Published var lastCheckDate: Date?
    
    init() {
        // Initialize Sparkle updater
        // The appcast URL is configured via Info.plist or SUFeedURL
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Observe updater state
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }
    
    /// Check for updates manually
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
        lastCheckDate = Date()
    }
    
    /// Enable/disable automatic updates
    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
    
    /// Update interval in seconds (default: 86400 = 24 hours)
    var updateCheckInterval: Double {
        get { updaterController.updater.updateCheckInterval }
        set { updaterController.updater.updateCheckInterval = newValue }
    }
    
    /// Get the current version string
    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    /// Get the build number
    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
