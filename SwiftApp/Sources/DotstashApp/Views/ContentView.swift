import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var manager: DotstashManager
    @State private var showAddSheet = false
    @State private var selectedDotfile: DotfileEntry?
    @State private var isDragOver = false
    @State private var droppedFiles: [String] = []
    @State private var showImportPicker = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebar
        } detail: {
            // Main content
            detailView
                .onDrop(of: [.fileURL], delegate: DropHandler(isDragOver: $isDragOver, droppedFiles: $droppedFiles, manager: manager))
        }
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
        .alert("Error", isPresented: .init(
            get: { manager.errorMessage != nil },
            set: { if !$0 { manager.clearMessages() } }
        )) {
            Button("OK") { manager.clearMessages() }
        } message: {
            Text(manager.errorMessage ?? "")
        }
        .alert("Success", isPresented: .init(
            get: { manager.successMessage != nil },
            set: { if !$0 { manager.clearMessages() } }
        )) {
            Button("OK") { manager.clearMessages() }
        } message: {
            Text(manager.successMessage ?? "")
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List {
            // Stats section
            Section {
                StatRow(label: "Total", value: "\(manager.totalCount)", icon: "tray.full")
                StatRow(label: "Healthy", value: "\(manager.healthyCount)", icon: "checkmark.circle")
                StatRow(label: "Warnings", value: "\(manager.warningCount)", icon: "exclamationmark.triangle")
            } header: {
                Text("Dashboard")
            }
            
            // Quick actions
            Section {
                Button(action: { showAddSheet = true }) {
                    Label("Add Dotfile", systemImage: "plus.circle")
                }
                
                Button(action: { manager.linkAll() }) {
                    Label("Link All", systemImage: "link")
                }
                .disabled(manager.dotfiles.isEmpty)
                
                Button(action: { _ = manager.exportStash() }) {
                    Label("Export Stash", systemImage: "square.and.arrow.up")
                }
                .disabled(manager.dotfiles.isEmpty)
                
                Button(action: { showImportPicker = true }) {
                    Label("Import Stash", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Actions")
            }
            
            // Dotfiles list
            Section {
                if manager.dotfiles.isEmpty {
                    Text("No dotfiles stashed yet")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(manager.dotfiles) { entry in
                        DotfileRow(entry: entry)
                            .tag(entry)
                    }
                }
            } header: {
                Text("Tracked Dotfiles")
            }
        }
        .navigationTitle("Dotstash")
    }
    
    // MARK: - Detail View
    
    private var detailView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("📦 Dotstash Dashboard")
                        .font(.title2.bold())
                    Spacer()
                    
                    // Live indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green.opacity(0.5), radius: 4)
                        Text("Live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1), in: Capsule())
                    
                    Button(action: { manager.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Manual refresh")
                    
                    Button(action: { showAddSheet = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Divider()
                
                // Content
                if manager.dotfiles.isEmpty {
                    emptyState
                } else {
                    DotfileGridView()
                }
            }
            
            // Drop overlay
            if isDragOver {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.15))
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                            Text("Drop files to stash")
                                .font(.title2.bold())
                                .foregroundStyle(.blue)
                            Text("Files will be copied to ~/.dotstash/")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(40)
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Dotfiles Stashed Yet")
                .font(.title2.bold())
            
            Text("Add your first dotfile to get started.\nYour configs will be safely stored in ~/.dotstash/")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button(action: { showAddSheet = true }) {
                Label("Add Your First Dotfile", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Drag hint
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundStyle(.secondary)
                Text("or drag files here from Finder")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Drop Handler

struct DropHandler: DropDelegate {
    @Binding var isDragOver: Bool
    @Binding var droppedFiles: [String]
    let manager: DotstashManager
    
    func performDrop(info: DropInfo) -> Bool {
        isDragOver = false
        
        let providers = info.itemProviders(for: [.fileURL])
        guard !providers.isEmpty else { return false }
        
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                
                let path = url.path
                
                DispatchQueue.main.async {
                    manager.addDotfile(path)
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isDragOver = true
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isDragOver = false
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(label)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

// MARK: - Dotfile Row (Sidebar)

struct DotfileRow: View {
    let entry: DotfileEntry
    
    var body: some View {
        HStack {
            Image(systemName: entry.isDirectory ? "folder" : "doc.text")
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.basename)
                    .font(.callout)
                
                HStack(spacing: 4) {
                    Image(systemName: entry.health.iconName)
                        .font(.caption2)
                    Text(entry.health.label)
                        .font(.caption2)
                }
                .foregroundStyle(entry.health == .healthy ? .green : .orange)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DotstashManager())
}
