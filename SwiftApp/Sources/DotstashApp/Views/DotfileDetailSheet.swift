import SwiftUI

enum DetailTab: String, CaseIterable {
    case stashed = "Stashed"
    case live = "Live"
    case diff = "Diff"
}

struct DotfileDetailSheet: View {
    @EnvironmentObject var manager: DotstashManager
    let entry: DotfileEntry
    @Binding var isPresented: Bool
    @State private var selectedTab: DetailTab = .diff
    @State private var showRestoreConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc.text.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading) {
                    Text(entry.basename)
                        .font(.title2.bold())
                    Text(entry.health.label)
                        .font(.caption)
                        .foregroundStyle(entry.health == .healthy ? .green : .orange)
                }
                
                Spacer()
                
                // Language badge
                if !entry.isDirectory {
                    let lang = SyntaxHighlighter.detectLanguage(filename: entry.basename)
                    if lang != .plain {
                        Text(lang.name)
                            .font(.caption.monospaced())
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.purple.opacity(0.1), in: Capsule())
                    }
                }
                
                // Diff summary badge
                if !entry.isDirectory, let summary = diffSummary {
                    if summary.hasChanges {
                        Label(summary.description, systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15), in: Capsule())
                    } else {
                        Label("Identical", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.15), in: Capsule())
                    }
                }
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Tab picker
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Content
            if entry.isDirectory {
                directoryView
            } else {
                switch selectedTab {
                case .stashed:
                    fileContentView(path: entry.stashed)
                case .live:
                    fileContentView(path: entry.source)
                case .diff:
                    diffView
                }
            }
            
            Divider()
            
            // Bottom actions
            HStack {
                if !entry.isDirectory, let summary = diffSummary, summary.hasChanges {
                    Button(action: { showRestoreConfirm = true }) {
                        Label("Restore from Stash", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                
                Button(action: { manager.linkDotfile(entry) }) {
                    Label("Link to Home", systemImage: "link")
                }
                .buttonStyle(.bordered)
                
                Button(role: .destructive) {
                    manager.removeDotfile(entry)
                    isPresented = false
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Done") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 750, height: 550)
        .confirmationDialog(
            "Restore \(entry.basename)?",
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button("Restore (overwrite live file)", role: .destructive) {
                manager.restoreDotfile(entry)
                isPresented = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace the current file at \(entry.source) with the stashed version from \(entry.stashed).")
        }
    }
    
    // MARK: - Diff Summary
    
    private var diffSummary: DiffSummary? {
        guard let stashed = manager.fileContents(at: entry.stashed),
              let live = manager.fileContents(at: entry.source) else {
            return nil
        }
        let lines = computeDiff(stashed: stashed, live: live)
        return DiffSummary(from: lines)
    }
    
    // MARK: - Diff View
    
    private var diffView: some View {
        Group {
            if let stashed = manager.fileContents(at: entry.stashed),
               let live = manager.fileContents(at: entry.source) {
                DiffViewer(
                            stashedContent: stashed,
                            liveContent: live,
                            filename: entry.name,
                            onRestore: { showRestoreConfirm = true }
                        )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("Unable to read one or both versions")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Directory View
    
    private var directoryView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("Directory")
                .font(.title3.bold())
            Text("This is a directory — contents can be viewed in Finder.")
                .foregroundStyle(.secondary)
            Button("Open in Finder") {
                let path = selectedTab == .stashed ? entry.stashed : entry.source
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - File Content View
    
    private func fileContentView(path: String) -> some View {
        let content = manager.fileContents(at: path) ?? "Unable to read file"
        
        return ScrollView([.horizontal, .vertical]) {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.background)
    }
}
