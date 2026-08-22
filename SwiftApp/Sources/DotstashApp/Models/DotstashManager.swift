import Foundation
import SwiftUI

// MARK: - DotstashManager

@MainActor
class DotstashManager: ObservableObject {
    @Published var dotfiles: [DotfileEntry] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let fileManager = FileManager.default
    private let stashDir: String
    private let configFile: String
    
    // File watching
    let fileWatcher = FileWatcher()
    @Published var lastRefresh = Date()
    
    // Status bar badge
    let statusBar = StatusBarController()
    
    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.stashDir = "\(home)/.dotstash"
        self.configFile = "\(stashDir)/dotstash.json"
        ensureStashDir()
        loadConfig()
        setupFileWatcher()
    }
    
    // MARK: - File Watcher Setup
    
    private func setupFileWatcher() {
        fileWatcher.onChange = { [weak self] in
            guard let self = self else { return }
            // Reload config and update watched paths
            self.loadConfig()
            self.restartWatching()
            self.updateBadge()
            self.lastRefresh = Date()
        }
        
        // Start watching stashed files
        restartWatching()
        updateBadge()
    }
    
    private func restartWatching() {
        var paths: [String] = []
        
        // Watch the config file
        paths.append(configFile)
        
        // Watch all stashed files
        for entry in dotfiles {
            paths.append(entry.stashed)
        }
        
        fileWatcher.restart(paths: paths)
    }
    
    // MARK: - Computed Stats
    
    var totalCount: Int { dotfiles.count }
    var healthyCount: Int { dotfiles.filter { $0.health == .healthy }.count }
    var warningCount: Int { totalCount - healthyCount }
    
    // MARK: - Config Management
    
    private func ensureStashDir() {
        if !fileManager.fileExists(atPath: stashDir) {
            try? fileManager.createDirectory(atPath: stashDir, withIntermediateDirectories: true)
        }
    }
    
    private func loadConfig() {
        guard fileManager.fileExists(atPath: configFile),
              let data = fileManager.contents(atPath: configFile) else {
            dotfiles = []
            return
        }
        
        do {
            let config = try JSONDecoder().decode(DotstashConfig.self, from: data)
            dotfiles = config.dotfiles.map { name, info in
                DotfileEntry(
                    name: name,
                    source: info.source,
                    stashed: info.stashed,
                    basename: info.basename ?? name,
                    stashedAt: info.stashedAt,
                    isDirectory: info.isDirectory
                )
            }.sorted { $0.basename < $1.basename }
        } catch {
            errorMessage = "Failed to load config: \(error.localizedDescription)"
            dotfiles = []
        }
    }
    
    private func saveConfig() {
        var dict: [String: DotfileInfo] = [:]
        for entry in dotfiles {
            dict[entry.name] = DotfileInfo(
                source: entry.source,
                stashed: entry.stashed,
                basename: entry.basename,
                stashedAt: entry.stashedAt,
                lastSyncedAt: nil,
                isDirectory: entry.isDirectory,
                hash: nil
            )
        }
        let config = DotstashConfig(dotfiles: dict, created: ISO8601DateFormatter().string(from: Date()))
        
        do {
            let data = try JSONEncoder().encode(config)
            let prettyData = try JSONSerialization.data(withJSONObject: try JSONSerialization.jsonObject(with: data), options: .prettyPrinted)
            try prettyData.write(to: URL(fileURLWithPath: configFile))
        } catch {
            errorMessage = "Failed to save config: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Actions
    
    func addDotfile(_ path: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fullPath = path.hasPrefix("/") ? path : "\(home)/\(path)"
        
        guard fileManager.fileExists(atPath: fullPath) else {
            errorMessage = "File not found: \(fullPath)"
            return
        }
        
        let name = (fullPath as NSString).lastPathComponent
        let stashedPath = "\(stashDir)/\(name)"
        var isDir = ObjCBool(false)
        fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
        
        do {
            // Remove existing stashed copy if present
            if fileManager.fileExists(atPath: stashedPath) {
                try fileManager.removeItem(atPath: stashedPath)
            }
            
            if isDir.boolValue {
                try fileManager.copyItem(atPath: fullPath, toPath: stashedPath)
            } else {
                try fileManager.copyItem(atPath: fullPath, toPath: stashedPath)
            }
        } catch {
            errorMessage = "Failed to copy: \(error.localizedDescription)"
            return
        }
        
        let entry = DotfileEntry(
            name: name,
            source: fullPath,
            stashed: stashedPath,
            basename: name,
            stashedAt: ISO8601DateFormatter().string(from: Date()),
            isDirectory: isDir.boolValue
        )
        
        // Remove existing entry with same name if present
        dotfiles.removeAll { $0.name == name }
        dotfiles.append(entry)
        dotfiles.sort { $0.name < $1.name }
        saveConfig()
        restartWatching()
        updateBadge()
        successMessage = "Stashed: \(name)"
    }
    
    func linkDotfile(_ entry: DotfileEntry) {
        guard fileManager.fileExists(atPath: entry.stashed) else {
            errorMessage = "Stashed file missing: \(entry.stashed)"
            return
        }
        
        // Remove existing
        if fileManager.fileExists(atPath: entry.source) {
            try? fileManager.removeItem(atPath: entry.source)
        }
        
        do {
            try fileManager.createSymbolicLink(atPath: entry.source, withDestinationPath: entry.stashed)
            successMessage = "Linked: \(entry.name)"
        } catch {
            errorMessage = "Failed to link: \(error.localizedDescription)"
        }
    }
    
    func linkAll() {
        var linked = 0
        for entry in dotfiles {
            linkDotfile(entry)
            if errorMessage == nil { linked += 1 }
        }
        successMessage = "Linked \(linked)/\(dotfiles.count) dotfiles"
    }
    
    func removeDotfile(_ entry: DotfileEntry, deleteStash: Bool = false) {
        if deleteStash && fileManager.fileExists(atPath: entry.stashed) {
            try? fileManager.removeItem(atPath: entry.stashed)
        }
        
        dotfiles.removeAll { $0.name == entry.name }
        saveConfig()
        restartWatching()
        successMessage = "Untracked: \(entry.name)"
    }
    
    func fileContents(at path: String) -> String? {
        guard let data = fileManager.contents(atPath: path) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Restore: overwrite live file with stashed version
    func restoreDotfile(_ entry: DotfileEntry) {
        guard fileManager.fileExists(atPath: entry.stashed) else {
            errorMessage = "Stashed file missing: \(entry.stashed)"
            return
        }
        
        // Remove existing file/dir at target
        if fileManager.fileExists(atPath: entry.source) {
            do {
                try fileManager.removeItem(atPath: entry.source)
            } catch {
                errorMessage = "Failed to remove existing: \(error.localizedDescription)"
                return
            }
        }
        
        // Copy stashed version to live location
        do {
            if entry.isDirectory {
                try fileManager.copyItem(atPath: entry.stashed, toPath: entry.source)
            } else {
                try fileManager.copyItem(atPath: entry.stashed, toPath: entry.source)
            }
            successMessage = "Restored: \(entry.name) ← stashed version"
        } catch {
            errorMessage = "Failed to restore: \(error.localizedDescription)"
        }
    }
    
    /// Force a manual refresh
    func refresh() {
        loadConfig()
        restartWatching()
        updateBadge()
        lastRefresh = Date()
    }
    
    func updateBadge() {
        statusBar.updateBadge(warningCount: warningCount)
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Export / Import
    
    /// Export all stashed dotfiles to a tarball
    func exportStash() -> URL? {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let exportName = "dotstash-export-\(timestamp).tar.gz"
        let exportURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent(exportName)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-czf", exportURL.path, "-C", stashDir, "."]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                successMessage = "Exported to: ~/Desktop/\(exportName)"
                return exportURL
            } else {
                errorMessage = "Export failed with status: \(process.terminationStatus)"
                return nil
            }
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Import dotfiles from a tarball
    func importStash(from url: URL) {
        // First, extract to a temp directory
        let tempDir = NSTemporaryDirectory() + "dotstash-import-\(UUID().uuidString)"
        
        do {
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        } catch {
            errorMessage = "Failed to create temp directory: \(error.localizedDescription)"
            return
        }
        
        // Extract the tarball
        let extractProcess = Process()
        extractProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        extractProcess.arguments = ["-xzf", url.path, "-C", tempDir]
        
        do {
            try extractProcess.run()
            extractProcess.waitUntilExit()
            
            guard extractProcess.terminationStatus == 0 else {
                errorMessage = "Failed to extract archive"
                try? FileManager.default.removeItem(atPath: tempDir)
                return
            }
        } catch {
            errorMessage = "Extract failed: \(error.localizedDescription)"
            try? FileManager.default.removeItem(atPath: tempDir)
            return
        }
        
        // Find all files in the extracted directory (skip dotstash.json)
        let contents = try? FileManager.default.contentsOfDirectory(atPath: tempDir)
        guard let files = contents else {
            errorMessage = "No files found in archive"
            try? FileManager.default.removeItem(atPath: tempDir)
            return
        }
        
        var imported = 0
        for file in files {
            if file == "dotstash.json" { continue } // Skip config, we'll rebuild it
            
            let srcPath = tempDir + "/" + file
            let dstPath = stashDir + "/" + file
            
            // Remove existing if present
            if FileManager.default.fileExists(atPath: dstPath) {
                try? FileManager.default.removeItem(atPath: dstPath)
            }
            
            do {
                try FileManager.default.copyItem(atPath: srcPath, toPath: dstPath)
                imported += 1
            } catch {
                print("Failed to import \(file): \(error)")
            }
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(atPath: tempDir)
        
        // Reload config
        loadConfig()
        restartWatching()
        updateBadge()
        
        successMessage = "Imported \(imported) file(s) from archive"
    }
}
