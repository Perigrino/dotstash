import Foundation
import Sparkle

// MARK: - Updater Controller

/// Wrapper around Sparkle's SPUUpdater for auto-updates.
/// Provides a simple interface for the SwiftUI app.
@MainActor
class UpdaterController: ObservableObject {
    private var updaterController: SPUStandardUpdaterController?
    
    @Published var canCheckForUpdates = false
    @Published var lastCheckDate: Date?
    @Published var isUpdaterEnabled = false
    
    init() {
        // Check if Sparkle is properly configured
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
        
        // Only enable updater if keys are configured (not placeholder values)
        if !publicKey.isEmpty && 
           !publicKey.contains("YOUR_SPARKLE_PUBLIC_KEY_HERE") &&
           !feedURL.contains("YOUR_USERNAME") {
            
            updaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
            
            // Observe updater state
            updaterController?.updater.publisher(for: \.canCheckForUpdates)
                .receive(on: DispatchQueue.main)
                .assign(to: &$canCheckForUpdates)
            
            isUpdaterEnabled = true
            print("✅ Sparkle updater enabled")
        } else {
            print("⚠️ Sparkle updater disabled (not configured)")
            isUpdaterEnabled = false
            canCheckForUpdates = false
        }
    }
    
    /// Check for updates manually
    func checkForUpdates() {
        guard isUpdaterEnabled, let updater = updaterController else {
            print("⚠️ Updater not configured")
            return
        }
        updater.checkForUpdates(nil)
        lastCheckDate = Date()
    }
    
    /// Enable/disable automatic updates
    var automaticallyChecksForUpdates: Bool {
        get { updaterController?.updater.automaticallyChecksForUpdates ?? false }
        set { updaterController?.updater.automaticallyChecksForUpdates = newValue }
    }
    
    /// Update interval in seconds (default: 86400 = 24 hours)
    var updateCheckInterval: Double {
        get { updaterController?.updater.updateCheckInterval ?? 86400 }
        set { updaterController?.updater.updateCheckInterval = newValue }
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
