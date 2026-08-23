import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: DotstashManager
    @EnvironmentObject var updaterController: UpdaterController
    @State private var showAddSheet = false
    @State private var showMainWindow = false
    @State private var showImportPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "tray.full.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Dotstash")
                    .font(.headline.bold())
                Spacer()
                
                if manager.warningCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text("\(manager.warningCount)")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.red, in: Capsule())
                }
                
                Text("\(manager.totalCount) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
            
            // Stats bar
            HStack(spacing: 16) {
                MenuBarStat(
                    value: "\(manager.healthyCount)",
                    label: "Healthy",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                MenuBarStat(
                    value: "\(manager.warningCount)",
                    label: "Warnings",
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Quick dotfile list
            if manager.dotfiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No dotfiles stashed yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(manager.dotfiles.prefix(6)) { entry in
                            MenuBarDotfileRow(entry: entry)
                        }
                        
                        if manager.dotfiles.count > 6 {
                            Text("+ \(manager.dotfiles.count - 6) more...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: min(CGFloat(manager.dotfiles.count) * 36 + 8, 220))
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 4) {
                MenuBarAction(
                    icon: "plus.circle",
                    title: "Add Dotfile",
                    color: .blue
                ) {
                    showAddSheet = true
                }
                
                MenuBarAction(
                    icon: "link",
                    title: "Link All",
                    color: .green
                ) {
                    manager.linkAll()
                }
                .disabled(manager.dotfiles.isEmpty)
                
                MenuBarAction(
                    icon: "square.and.arrow.up",
                    title: "Export Stash",
                    color: .blue
                ) {
                    _ = manager.exportStash()
                }
                .disabled(manager.dotfiles.isEmpty)
                
                MenuBarAction(
                    icon: "square.and.arrow.down",
                    title: "Import Stash",
                    color: .purple
                ) {
                    showImportPicker = true
                }
                
                MenuBarAction(
                    icon: "arrow.up.left.arrow.down.right",
                    title: "Open Dashboard",
                    color: .purple
                ) {
                    openMainWindow()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Updates & Quit
            if updaterController.isUpdaterEnabled {
                MenuBarAction(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Check for Updates...",
                    color: .blue
                ) {
                    updaterController.checkForUpdates()
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Updates not configured")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            
            MenuBarAction(
                icon: "xmark.circle",
                title: "Quit Dotstash",
                color: .red
                ) {
                    NSApplication.shared.terminate(nil)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 300)
        .sheet(isPresented: $showAddSheet) {
            AddDotfileSheet(isPresented: $showAddSheet)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                manager.importStash(from: url)
            }
        }
        .alert("Success", isPresented: .init(
            get: { manager.successMessage != nil },
            set: { if !$0 { manager.clearMessages() } }
        )) {
            Button("OK") { manager.clearMessages() }
        } message: {
            Text(manager.successMessage ?? "")
        }
        .alert("Error", isPresented: .init(
            get: { manager.errorMessage != nil },
            set: { if !$0 { manager.clearMessages() } }
        )) {
            Button("OK") { manager.clearMessages() }
        } message: {
            Text(manager.errorMessage ?? "")
        }
    }
    
    private func openMainWindow() {
        for window in NSApplication.shared.windows {
            if window.title != "Dotstash" && window.title.contains("") {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }
        }
        // If no window found, try to activate the app
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

// MARK: - Menu Bar Stat

struct MenuBarStat: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Menu Bar Dotfile Row

struct MenuBarDotfileRow: View {
    @EnvironmentObject var manager: DotstashManager
    let entry: DotfileEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.health.iconName)
                .font(.caption)
                .foregroundStyle(entry.health == .healthy ? .green : .orange)
                .frame(width: 16)
            
            Text(entry.basename)
                .font(.callout.monospaced())
                .lineLimit(1)
            
            Spacer()
            
            Button(action: { manager.linkDotfile(entry) }) {
                Image(systemName: "link")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Link this file")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Menu Bar Action

struct MenuBarAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(title)
                    .font(.callout)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
