import SwiftUI
import AppKit

struct AddDotfileSheet: View {
    @EnvironmentObject var manager: DotstashManager
    @Binding var isPresented: Bool
    @State private var filePath = ""
    @State private var showFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text("Add Dotfile")
                    .font(.title2.bold())
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Input
            VStack(alignment: .leading, spacing: 8) {
                Text("File Path")
                    .font(.headline)
                
                HStack {
                    TextField(".zshrc, .gitconfig, .config/nvim", text: $filePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.body.monospaced())
                    
                    Button(action: { showFilePicker = true }) {
                        Label("Browse", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("Enter the path relative to your home directory, or an absolute path.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Common dotfiles
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(commonDotfiles, id: \.self) { name in
                        Button(action: { filePath = name }) {
                            Text(name)
                                .font(.caption.monospaced())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: addDotfile) {
                    Label("Add to Stash", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(filePath.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500, height: 380)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                let path = url.path
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                filePath = path.replacingOccurrences(of: home, with: "~")
                if filePath.hasPrefix("~") {
                    filePath = String(filePath.dropFirst())
                }
            }
        }
    }
    
    private func addDotfile() {
        let trimmed = filePath.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        manager.addDotfile(trimmed)
        if manager.errorMessage == nil {
            isPresented = false
        }
    }
    
    private let commonDotfiles = [
        ".zshrc", ".bashrc", ".bash_profile", ".gitconfig",
        ".vimrc", ".tmux.conf", ".npmrc", ".ssh/config"
    ]
}
