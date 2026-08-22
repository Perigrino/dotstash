import SwiftUI
import AppKit

// MARK: - Status Bar Controller

/// Manages the macOS status bar item with badge for Dotstash.
@MainActor
class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    
    /// Create and manage our own status bar item with badge
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "tray.full.fill", accessibilityDescription: "Dotstash")
            button.image?.isTemplate = true
        }
    }
    
    /// Update the badge (shown as title next to icon)
    func updateBadge(warningCount: Int) {
        guard let button = statusItem?.button else { return }
        
        if warningCount > 0 {
            button.title = " \(warningCount)"
        } else {
            button.title = ""
        }
    }
    
    /// Remove the status bar item
    func teardown() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }
}
