import Foundation

// MARK: - Dotfile Model

struct DotfileEntry: Codable, Identifiable, Hashable {
    var id: String { name }
    
    let name: String
    let source: String
    let stashed: String
    let basename: String
    let stashedAt: String
    let isDirectory: Bool
    
    // Computed properties
    var sourceExists: Bool {
        FileManager.default.fileExists(atPath: source)
    }
    
    var stashedExists: Bool {
        FileManager.default.fileExists(atPath: stashed)
    }
    
    var isLinked: Bool {
        guard sourceExists else { return false }
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: source, isDirectory: &isDir)
        // Check if it's a symlink by trying to read the symlink attributes
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: source)
            return attrs[.type] as? FileAttributeType == .typeSymbolicLink
        } catch {
            return false
        }
    }
    
    enum HealthStatus {
        case healthy
        case notLinked
        case missingFromHome
        case missingStash
        
        var label: String {
            switch self {
            case .healthy: return "Linked & Up to Date"
            case .notLinked: return "Not Symlinked"
            case .missingFromHome: return "Missing from Home"
            case .missingStash: return "Stash Missing"
            }
        }
        
        var iconName: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .notLinked: return "link.badge.xmark"
            case .missingFromHome: return "questionmark.circle.fill"
            case .missingStash: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var health: HealthStatus {
        if !stashedExists { return .missingStash }
        if !sourceExists { return .missingFromHome }
        if !isLinked { return .notLinked }
        return .healthy
    }
}

// MARK: - Config File Structure

struct DotstashConfig: Codable {
    var dotfiles: [String: DotfileInfo]
    let created: String
    
    init() {
        self.dotfiles = [:]
        self.created = ISO8601DateFormatter().string(from: Date())
    }
    
    init(dotfiles: [String: DotfileInfo], created: String) {
        self.dotfiles = dotfiles
        self.created = created
    }
}

struct DotfileInfo: Codable {
    let source: String
    let stashed: String
    let basename: String?
    let stashedAt: String
    let lastSyncedAt: String?
    let isDirectory: Bool
    let hash: String?
}
