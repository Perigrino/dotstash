import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var updaterController: UpdaterController
    @AppStorage("autoCheckUpdates") private var autoCheckUpdates = true
    @AppStorage("updateInterval") private var updateInterval = 86400.0
    
    var body: some View {
        TabView {
            GeneralSettingsTab(autoCheckUpdates: $autoCheckUpdates, updateInterval: $updateInterval)
                .tabItem { Label("General", systemImage: "gear") }
            
            UpdatesSettingsTab(updaterController: updaterController)
                .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
            
            AboutTab(updaterController: updaterController)
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 300)
        .onChange(of: autoCheckUpdates) { newValue in
            updaterController.automaticallyChecksForUpdates = newValue
        }
        .onChange(of: updateInterval) { newValue in
            updaterController.updateCheckInterval = newValue
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @Binding var autoCheckUpdates: Bool
    @Binding var updateInterval: Double
    
    var body: some View {
        Form {
            Section {
                Toggle("Automatically check for updates", isOn: $autoCheckUpdates)
                
                if autoCheckUpdates {
                    Picker("Check every:", selection: $updateInterval) {
                        Text("Every 12 hours").tag(43200.0)
                        Text("Every day").tag(86400.0)
                        Text("Every week").tag(604800.0)
                    }
                }
            } header: {
                Text("Updates")
            } footer: {
                Text("Dotstash will check for updates in the background when this is enabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Updates Settings

struct UpdatesSettingsTab: View {
    @ObservedObject var updaterController: UpdaterController
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Current Version")
                    Spacer()
                    Text("\(updaterController.currentVersion) (\(updaterController.buildNumber))")
                        .foregroundStyle(.secondary)
                }
                
                if let lastCheck = updaterController.lastCheckDate {
                    HStack {
                        Text("Last Checked")
                        Spacer()
                        Text(lastCheck.formatted())
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button(action: {
                    updaterController.checkForUpdates()
                }) {
                    Label("Check for Updates Now", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(!updaterController.canCheckForUpdates)
            } header: {
                Text("Updates")
            }
        }
        .padding()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    @ObservedObject var updaterController: UpdaterController
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("Dotstash")
                .font(.title.bold())
            
            Text("Version \(updaterController.currentVersion)")
                .foregroundStyle(.secondary)
            
            Text("A native macOS dotfiles manager")
                .foregroundStyle(.secondary)
            
            Divider()
            
            Text("© 2026 Perigrino. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UpdaterController())
}
