import Foundation
import Dispatch

// MARK: - File Watcher

/// Monitors files and directories for changes using GCD DispatchSource
@MainActor
class FileWatcher: ObservableObject {
    private var sources: [DispatchSourceFileSystemObject] = []
    private var fileDescriptors: [Int32] = []
    private let queue = DispatchQueue(label: "com.dotstash.filewatcher", attributes: .concurrent)
    
    var onChange: (() -> Void)?
    
    /// Start watching a file
    func watch(path: String) {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            print("⚠️  Could not watch: \(path)")
            return
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: queue
        )
        
        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.onChange?()
            }
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        sources.append(source)
        fileDescriptors.append(fd)
    }
    
    /// Start watching multiple paths
    func watch(paths: [String]) {
        for path in paths {
            watch(path: path)
        }
    }
    
    /// Stop all watchers
    func stopAll() {
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
        fileDescriptors.removeAll()
    }
    
    /// Restart watching with new paths
    func restart(paths: [String]) {
        stopAll()
        watch(paths: paths)
    }
    
    deinit {
        for fd in fileDescriptors {
            close(fd)
        }
        for source in sources {
            source.cancel()
        }
    }
}
