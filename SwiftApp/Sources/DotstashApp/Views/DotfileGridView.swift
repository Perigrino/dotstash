import SwiftUI

struct DotfileGridView: View {
    @EnvironmentObject var manager: DotstashManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 16)
            ], spacing: 16) {
                ForEach(manager.dotfiles) { entry in
                    DotfileCard(entry: entry)
                }
            }
            .padding()
        }
    }
}

// MARK: - Dotfile Card

struct DotfileCard: View {
    @EnvironmentObject var manager: DotstashManager
    let entry: DotfileEntry
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text(entry.basename)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Health badge
                Image(systemName: entry.health.iconName)
                    .foregroundStyle(entry.health == .healthy ? .green : .orange)
            }
            
            // Paths
            VStack(alignment: .leading, spacing: 4) {
                PathRow(label: "Source", path: entry.source)
                PathRow(label: "Stash", path: entry.stashed)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            // Type & date
            HStack {
                Label(entry.isDirectory ? "Directory" : "File", systemImage: entry.isDirectory ? "folder" : "doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatDate(entry.stashedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: { manager.linkDotfile(entry) }) {
                    Label("Link", systemImage: "link")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: { showDetail = true }) {
                    Label("View", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button(role: .destructive) {
                    manager.removeDotfile(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showDetail) {
            DotfileDetailSheet(entry: entry, isPresented: $showDetail)
        }
    }
    
    private func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}

// MARK: - Path Row

struct PathRow: View {
    let label: String
    let path: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .bold()
                .frame(width: 42, alignment: .trailing)
            Text(shortenPath(path))
                .lineLimit(1)
        }
    }
    
    private func shortenPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.replacingOccurrences(of: home, with: "~")
    }
}
