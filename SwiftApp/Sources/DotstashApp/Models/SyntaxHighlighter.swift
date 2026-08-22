import SwiftUI

// MARK: - Syntax Highlighter

/// Simple syntax highlighting for common config file types
struct SyntaxHighlighter {
    
    // MARK: - Language Detection
    
    enum Language {
        case shell
        case gitConfig
        case vim
        case tmux
        case json
        case yaml
        case toml
        case css
        case plain
        
        var name: String {
            switch self {
            case .shell: return "Shell"
            case .gitConfig: return "Git Config"
            case .vim: return "Vim"
            case .tmux: return "Tmux"
            case .json: return "JSON"
            case .yaml: return "YAML"
            case .toml: return "TOML"
            case .css: return "CSS"
            case .plain: return "Plain Text"
            }
        }
    }
    
    /// Detect language from filename
    static func detectLanguage(filename: String) -> Language {
        let name = filename.lowercased()
        
        if name.hasSuffix(".sh") || name.hasSuffix(".zsh") || name.hasSuffix(".bash") ||
           name == ".zshrc" || name == ".bashrc" || name == ".bash_profile" ||
           name == ".bash_aliases" || name == ".profile" || name == ".zprofile" {
            return .shell
        }
        
        if name.hasSuffix(".gitconfig") || name == ".gitconfig" || name.hasSuffix(".gitignore") {
            return .gitConfig
        }
        
        if name.hasSuffix(".vim") || name == ".vimrc" || name.hasSuffix("vimrc") ||
           name.contains("vim") {
            return .vim
        }
        
        if name.hasSuffix(".tmux") || name == ".tmux.conf" || name.hasSuffix("tmux.conf") {
            return .tmux
        }
        
        if name.hasSuffix(".json") || name == "package.json" || name == "tsconfig.json" {
            return .json
        }
        
        if name.hasSuffix(".yaml") || name.hasSuffix(".yml") {
            return .yaml
        }
        
        if name.hasSuffix(".toml") || name == "Cargo.toml" {
            return .toml
        }
        
        if name.hasSuffix(".css") {
            return .css
        }
        
        return .plain
    }
    
    // MARK: - Highlighting Rules
    
    struct Token {
        let text: String
        let color: Color
    }
    
    /// Tokenize a line for a specific language
    static func highlightLine(_ line: String, language: Language) -> [Token] {
        switch language {
        case .shell:
            return highlightShell(line)
        case .gitConfig:
            return highlightGitConfig(line)
        case .vim:
            return highlightVim(line)
        case .tmux:
            return highlightTmux(line)
        case .json:
            return highlightJSON(line)
        case .yaml:
            return highlightYAML(line)
        case .toml:
            return highlightTOML(line)
        case .css:
            return highlightCSS(line)
        case .plain:
            return [Token(text: line, color: .primary)]
        }
    }
    
    // MARK: - Shell Highlighting
    
    private static func highlightShell(_ line: String) -> [Token] {
        var tokens: [Token] = []
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Full-line comment
        if trimmed.hasPrefix("#") {
            return [Token(text: line, color: .green)]
        }
        
        // Keyword highlighting
        let keywords = ["if", "then", "else", "elif", "fi", "for", "while", "do", "done",
                       "case", "esac", "function", "return", "exit", "export", "source",
                       "alias", "unset", "readonly", "local", "declare", "set", "unset"]
        
        let assignments = ["export", "local", "declare", "readonly", "set"]
        
        let remaining = line
        var pos = 0
        
        while pos < remaining.count {
            let substring = String(remaining[remaining.index(remaining.startIndex, offsetBy: pos)...])
            
            // Check for comment
            if let commentRange = substring.range(of: "#") {
                let beforeComment = String(substring[substring.startIndex..<commentRange.lowerBound])
                if !beforeComment.isEmpty {
                    tokens.append(Token(text: beforeComment, color: .primary))
                }
                let comment = String(substring[commentRange.lowerBound...])
                tokens.append(Token(text: comment, color: .green))
                break
            }
            
            // Check for string (single quotes)
            if substring.hasPrefix("'") {
                if let endQuote = substring.dropFirst().firstIndex(of: "'") {
                    let range = substring.index(substring.startIndex, offsetBy: 0)...substring.index(after: endQuote)
                    tokens.append(Token(text: String(substring[range]), color: .yellow))
                    pos += substring[range].count
                    continue
                }
            }
            
            // Check for string (double quotes)
            if substring.hasPrefix("\"") {
                if let endQuote = substring.dropFirst().firstIndex(of: "\"") {
                    let range = substring.index(substring.startIndex, offsetBy: 0)...substring.index(after: endQuote)
                    tokens.append(Token(text: String(substring[range]), color: .yellow))
                    pos += substring[range].count
                    continue
                }
            }
            
            // Check for variable ($)
            if substring.hasPrefix("$") {
                let varEnd = substring.dropFirst().firstIndex { !$0.isLetter && !$0.isNumber && $0 != "_" } ?? substring.endIndex
                let range = substring.startIndex..<varEnd
                tokens.append(Token(text: String(substring[range]), color: .cyan))
                pos += substring[range].count
                continue
            }
            
            // Check for keywords
            var foundKeyword = false
            for keyword in keywords {
                if substring.hasPrefix(keyword) {
                    let afterKeyword = substring.index(substring.startIndex, offsetBy: keyword.count)
                    if afterKeyword == substring.endIndex || !substring[afterKeyword].isLetter {
                        let color: Color = assignments.contains(keyword) ? .purple : .pink
                        tokens.append(Token(text: keyword, color: color))
                        pos += keyword.count
                        foundKeyword = true
                        break
                    }
                }
            }
            if foundKeyword { continue }
            
            // Check for numbers
            if substring.first?.isNumber == true {
                let numEnd = substring.firstIndex { !$0.isNumber && $0 != "." } ?? substring.endIndex
                let range = substring.startIndex..<numEnd
                tokens.append(Token(text: String(substring[range]), color: .orange))
                pos += substring[range].count
                continue
            }
            
            // Default: add one character
            tokens.append(Token(text: String(substring.first!), color: .primary))
            pos += 1
        }
        
        return tokens.isEmpty ? [Token(text: line, color: .primary)] : tokens
    }
    
    // MARK: - Git Config Highlighting
    
    private static func highlightGitConfig(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Comment
        if trimmed.hasPrefix("#") || trimmed.hasPrefix(";") {
            return [Token(text: line, color: .green)]
        }
        
        // Section header [section]
        if trimmed.hasPrefix("[") && trimmed.contains("]") {
            return [Token(text: line, color: .purple)]
        }
        
        // Key = Value
        if let eqIndex = line.firstIndex(of: "=") {
            let key = String(line[line.startIndex..<eqIndex]).trimmingCharacters(in: .whitespaces)
            let eq = String(line[eqIndex])
            let value = String(line[line.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
            
            return [
                Token(text: key, color: .cyan),
                Token(text: " \(eq) ", color: .primary),
                Token(text: value, color: .yellow)
            ]
        }
        
        return [Token(text: line, color: .primary)]
    }
    
    // MARK: - Vim Highlighting
    
    private static func highlightVim(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Comment
        if trimmed.hasPrefix("\"") {
            return [Token(text: line, color: .green)]
        }
        
        // Commands
        let commands = ["set", "let", "map", "nmap", "vmap", "imap", "nnoremap", "vnoremap", "inoremap",
                       "syntax", "filetype", "colorscheme", "highlight", "autocmd", "augroup"]
        
        for cmd in commands {
            if trimmed.hasPrefix(cmd) {
                let rest = String(line.dropFirst(cmd.count))
                return [
                    Token(text: cmd, color: .pink),
                    Token(text: rest, color: .primary)
                ]
            }
        }
        
        // Option = value
        if let eqIndex = line.firstIndex(of: "=") {
            let key = String(line[line.startIndex..<eqIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
            
            return [
                Token(text: key, color: .cyan),
                Token(text: "=", color: .primary),
                Token(text: value, color: .yellow)
            ]
        }
        
        return [Token(text: line, color: .primary)]
    }
    
    // MARK: - Tmux Highlighting
    
    private static func highlightTmux(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Comment
        if trimmed.hasPrefix("#") {
            return [Token(text: line, color: .green)]
        }
        
        // Option value
        if let spaceIndex = line.firstIndex(of: " ") {
            let key = String(line[line.startIndex..<spaceIndex])
            let value = String(line[line.index(after: spaceIndex)...])
            
            return [
                Token(text: key, color: .cyan),
                Token(text: " ", color: .primary),
                Token(text: value, color: .yellow)
            ]
        }
        
        return [Token(text: line, color: .primary)]
    }
    
    // MARK: - JSON Highlighting
    
    private static func highlightJSON(_ line: String) -> [Token] {
        var tokens: [Token] = []
        var inString = false
        var isKey = false
        let chars = Array(line)
        var i = 0
        
        while i < chars.count {
            let c = chars[i]
            let strIndex = line.index(line.startIndex, offsetBy: i)
            
            if c == "\"" && (i == 0 || chars[i-1] != "\\") {
                if inString {
                    tokens.append(Token(text: "\"", color: .yellow))
                    inString = false
                } else {
                    // Check if this is a key (followed by :)
                    var j = i + 1
                    while j < chars.count && chars[j] != "\"" { j += 1 }
                    isKey = j + 1 < chars.count && chars[j + 1] == ":"
                    
                    tokens.append(Token(text: "\"", color: .yellow))
                    inString = true
                }
            } else if inString {
                tokens.append(Token(text: String(c), color: isKey ? .cyan : .yellow))
            } else if c.isNumber || (c == "-" && i + 1 < chars.count && chars[i+1].isNumber) {
                var j = i
                while j < chars.count && (chars[j].isNumber || chars[j] == "." || chars[j] == "-" || chars[j] == "e" || chars[j] == "E") { j += 1 }
                tokens.append(Token(text: String(chars[i..<j]), color: .orange))
                i = j - 1
            } else {
                // Check for keywords using string prefix
                let remaining = String(line[strIndex...])
                if remaining.hasPrefix("true") {
                    tokens.append(Token(text: "true", color: .purple))
                    i += 3
                } else if remaining.hasPrefix("false") {
                    tokens.append(Token(text: "false", color: .purple))
                    i += 4
                } else if remaining.hasPrefix("null") {
                    tokens.append(Token(text: "null", color: .purple))
                    i += 3
                } else {
                    tokens.append(Token(text: String(c), color: .primary))
                }
            }
            
            i += 1
        }
        
        return tokens.isEmpty ? [Token(text: line, color: .primary)] : tokens
    }
    
    // MARK: - YAML Highlighting
    
    private static func highlightYAML(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Comment
        if trimmed.hasPrefix("#") {
            return [Token(text: line, color: .green)]
        }
        
        // Key: value
        if let colonIndex = line.firstIndex(of: ":") {
            let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            
            if !key.isEmpty {
                var tokens: [Token] = []
                tokens.append(Token(text: key, color: .cyan))
                tokens.append(Token(text: ":", color: .primary))
                if !value.isEmpty {
                    tokens.append(Token(text: " \(value)", color: .yellow))
                }
                return tokens
            }
        }
        
        // List items
        if trimmed.hasPrefix("- ") {
            return [
                Token(text: "- ", color: .pink),
                Token(text: String(line.dropFirst(2)), color: .primary)
            ]
        }
        
        return [Token(text: line, color: .primary)]
    }
    
    // MARK: - TOML Highlighting
    
    private static func highlightTOML(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Comment
        if trimmed.hasPrefix("#") {
            return [Token(text: line, color: .green)]
        }
        
        // Section header [section]
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            return [Token(text: line, color: .purple)]
        }
        
        // Key = value
        if let eqIndex = line.firstIndex(of: "=") {
            let key = String(line[line.startIndex..<eqIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
            
            return [
                Token(text: key, color: .cyan),
                Token(text: " = ", color: .primary),
                Token(text: value, color: .yellow)
            ]
        }
        
        return [Token(text: line, color: .primary)]
    }
    
    // MARK: - CSS Highlighting
    
    private static func highlightCSS(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Comment
        if trimmed.hasPrefix("/*") || trimmed.hasPrefix("//") {
            return [Token(text: line, color: .green)]
        }
        
        // Selector (before {)
        if line.contains("{") {
            let beforeBrace = String(line.prefix(while: { $0 != "{" })).trimmingCharacters(in: .whitespaces)
            return [
                Token(text: beforeBrace, color: .pink),
                Token(text: " {", color: .primary)
            ]
        }
        
        // Property: value;
        if let colonIndex = line.firstIndex(of: ":"),
           let semiIndex = line.firstIndex(of: ";") {
            let property = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colonIndex)..<semiIndex]).trimmingCharacters(in: .whitespaces)
            
            return [
                Token(text: property, color: .cyan),
                Token(text: ": ", color: .primary),
                Token(text: value, color: .yellow),
                Token(text: ";", color: .primary)
            ]
        }
        
        return [Token(text: line, color: .primary)]
    }
}
