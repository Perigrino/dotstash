import SwiftUI

// MARK: - Diff Line Model

struct DiffLine: Identifiable {
    let id = UUID()
    let lineNumber: Int?
    let content: String
    let type: DiffType
    
    enum DiffType {
        case added, removed, unchanged, separator
        
        var color: Color {
            switch self {
            case .added: return .green
            case .removed: return .red
            case .unchanged: return .clear
            case .separator: return .clear
            }
        }
        
        var prefix: String {
            switch self {
            case .added: return "+"
            case .removed: return "−"
            case .unchanged: return " "
            case .separator: return "…"
            }
        }
    }
}

// MARK: - Diff Computation

func computeDiff(stashed: String, live: String) -> [DiffLine] {
    let sLines = stashed.components(separatedBy: .newlines)
    let lLines = live.components(separatedBy: .newlines)
    var result: [DiffLine] = []
    var lineNum = 0
    let lcs = longestCommonSubsequence(sLines, lLines)
    var si = 0, li = 0, lcsIdx = 0
    
    while si < sLines.count || li < lLines.count {
        if lcsIdx < lcs.count && si < sLines.count && li < lLines.count
            && sLines[si] == lcs[lcsIdx] && lLines[li] == lcs[lcsIdx] {
            lineNum += 1
            result.append(DiffLine(lineNumber: lineNum, content: sLines[si], type: .unchanged))
            si += 1; li += 1; lcsIdx += 1
        } else if si < sLines.count && (lcsIdx >= lcs.count || sLines[si] != lcs[lcsIdx]) {
            result.append(DiffLine(lineNumber: nil, content: sLines[si], type: .removed))
            si += 1
        } else if li < lLines.count && (lcsIdx >= lcs.count || lLines[li] != lcs[lcsIdx]) {
            lineNum += 1
            result.append(DiffLine(lineNumber: lineNum, content: lLines[li], type: .added))
            li += 1
        } else { break }
    }
    return result
}

func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
    let m = a.count, n = b.count
    var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
    for i in 1...m { for j in 1...n {
        dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
    }}
    var result: [String] = []
    var i = m, j = n
    while i > 0 && j > 0 {
        if a[i-1] == b[j-1] { result.append(a[i-1]); i -= 1; j -= 1 }
        else if dp[i-1][j] > dp[i][j-1] { i -= 1 } else { j -= 1 }
    }
    return result.reversed()
}

// MARK: - Diff Summary

struct DiffSummary {
    let added: Int, removed: Int, unchanged: Int
    var hasChanges: Bool { added > 0 || removed > 0 }
    var description: String {
        guard hasChanges else { return "Files are identical" }
        var p: [String] = []
        if added > 0 { p.append("+\(added)") }
        if removed > 0 { p.append("-\(removed)") }
        return p.joined(separator: " ")
    }
    init(from lines: [DiffLine]) {
        added = lines.filter { $0.type == .added }.count
        removed = lines.filter { $0.type == .removed }.count
        unchanged = lines.filter { $0.type == .unchanged }.count
    }
}

// MARK: - Diff View Mode

enum DiffViewMode: String, CaseIterable {
    case unified = "Unified"
    case sideBySide = "Side by Side"
}

// MARK: - Diff Viewer

struct DiffViewer: View {
    let stashedContent: String
    let liveContent: String
    let filename: String
    var onRestore: (() -> Void)?
    @State private var viewMode: DiffViewMode = .unified
    
    private var language: SyntaxHighlighter.Language {
        SyntaxHighlighter.detectLanguage(filename: filename)
    }
    private var diffLines: [DiffLine] { computeDiff(stashed: stashedContent, live: liveContent) }
    private var summary: DiffSummary { DiffSummary(from: diffLines) }
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            if summary.hasChanges {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(.blue)
                    Text(summary.description).font(.callout.monospaced().bold())
                    Spacer()
                    Picker("View", selection: $viewMode) {
                        ForEach(DiffViewMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 180)
                    if let onRestore {
                        Button(action: onRestore) {
                            Label("Restore", systemImage: "arrow.counterclockwise").font(.caption)
                        }.buttonStyle(.bordered).tint(.orange).controlSize(.small)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Text("\(summary.added) added")
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("\(summary.removed) removed")
                    }.font(.caption).foregroundStyle(.secondary)
                }.padding(.horizontal, 16).padding(.vertical, 10)
                 .background(.quaternary.opacity(0.5))
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Files are identical — no changes detected").font(.callout).foregroundStyle(.secondary)
                    Spacer()
                }.padding(.horizontal, 16).padding(.vertical, 10).background(.green.opacity(0.1))
            }
            Divider()
            if viewMode == .unified { unifiedDiffView } else { sideBySideDiffView }
        }
    }
    
    // Unified
    private var unifiedDiffView: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(diffLines) { line in DiffLineRow(line: line, language: language) }
            }.padding(.vertical, 8)
        }.background(Color(nsColor: .textBackgroundColor))
    }
    
    // Side-by-Side
    private var sideBySideDiffView: some View {
        let sLines = stashedContent.components(separatedBy: .newlines)
        let lLines = liveContent.components(separatedBy: .newlines)
        let max = max(sLines.count, lLines.count)
        return HSplitView {
            VStack(spacing: 0) {
                HStack { Image(systemName: "tray.full").foregroundStyle(.blue); Text("Stashed").font(.caption.bold()); Spacer() }
                    .padding(.horizontal, 12).padding(.vertical, 6).background(.blue.opacity(0.1))
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<max, id: \.self) { idx in
                            ssRow(line: idx < sLines.count ? sLines[idx] : "", num: idx+1,
                                  removed: idx < sLines.count && (idx >= lLines.count || sLines[idx] != lLines[idx]), added: false)
                        }
                    }.padding(.vertical, 8)
                }
            }.frame(minWidth: 250)
            VStack(spacing: 0) {
                HStack { Image(systemName: "doc.text").foregroundStyle(.green); Text("Live").font(.caption.bold()); Spacer() }
                    .padding(.horizontal, 12).padding(.vertical, 6).background(.green.opacity(0.1))
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<max, id: \.self) { idx in
                            ssRow(line: idx < lLines.count ? lLines[idx] : "", num: idx+1,
                                  removed: false, added: idx < lLines.count && (idx >= sLines.count || sLines[idx] != lLines[idx]))
                        }
                    }.padding(.vertical, 8)
                }
            }.frame(minWidth: 250)
        }.background(Color(nsColor: .textBackgroundColor))
    }
    
    private func ssRow(line: String, num: Int, removed: Bool, added: Bool) -> some View {
        let tokens = SyntaxHighlighter.highlightLine(line, language: language)
        return HStack(alignment: .top, spacing: 0) {
            Text("\(num)").font(.system(.caption, design: .monospaced)).foregroundStyle(.tertiary)
                .frame(width: 35, alignment: .trailing).padding(.trailing, 8)
            tokenText(tokens).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.horizontal, 12).padding(.vertical, 1)
         .background(removed ? Color.red.opacity(0.12) : added ? Color.green.opacity(0.12) : Color.clear)
    }
}

// MARK: - Token Text Helper

func tokenText(_ tokens: [SyntaxHighlighter.Token]) -> some View {
    HStack(spacing: 0) {
        ForEach(0..<tokens.count, id: \.self) { i in
            Text(tokens[i].text).foregroundStyle(tokens[i].color)
        }
    }
}

// MARK: - Diff Line Row

struct DiffLineRow: View {
    let line: DiffLine
    let language: SyntaxHighlighter.Language
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(line.lineNumber.map { "\($0)" } ?? "")
                .font(.system(.caption, design: .monospaced)).foregroundStyle(.tertiary)
                .frame(width: 40, alignment: .trailing).padding(.trailing, 8)
            Text(line.type.prefix)
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(line.type == .added ? .green : line.type == .removed ? .red : .secondary)
                .frame(width: 16, alignment: .center)
            let tokens = SyntaxHighlighter.highlightLine(line.content, language: language)
            tokenText(tokens).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.horizontal, 12).padding(.vertical, 1)
         .background(line.type.color.opacity(0.12))
    }
}

#Preview {
    DiffViewer(stashedContent: "hello\nworld\nfoo\nbar", liveContent: "hello\nworld\ntest\nbar\nbaz", filename: ".zshrc")
        .frame(width: 800, height: 500)
}
