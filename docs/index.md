---
layout: default
title: Home
---

# 📦 Dotstash

**A native macOS dotfiles manager** — stash, link, and restore your configs with a beautiful SwiftUI app or powerful CLI.

[![GitHub release](https://img.shields.io/github/v/release/perigrino/dotstash)](https://github.com/perigrino/dotstash/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/perigrino/dotstash/blob/main/LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue)](https://www.apple.com/macos/)

---

## 🚀 Quick Start

### Install via DMG

1. [Download the latest release](https://github.com/perigrino/dotstash/releases/latest)
2. Open the DMG file
3. Drag Dotstash to your Applications folder
4. Launch from Applications

### Install via CLI

```bash
git clone https://github.com/perigrino/dotstash.git
cd dotstash
npm install && npm link
dotstash --version
```

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📊 **Dashboard** | Visual grid of all your dotfiles with health status |
| 🔍 **Diff Viewer** | Unified and side-by-side diffs with syntax highlighting |
| 🎨 **Syntax Highlighting** | Shell, Git, Vim, JSON, YAML, TOML, CSS |
| 📁 **Drag & Drop** | Drop files from Finder to add them |
| 🔄 **Live Watching** | Auto-refreshes when files change |
| 🔗 **One-Click Link** | Symlink dotfiles back to home |
| ↩️ **Restore** | Overwrite live files with stashed versions |
| 📤 **Export/Import** | Bundle your stash for new machines |
| 🛡️ **Safety First** | Drift detection prevents data loss |
| 🌐 **Menu Bar** | Lives in your menu bar with badge count |
| ⚙️ **Auto-Update** | Sparkle-powered updates |

---

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Installation](installation.md) | Detailed installation instructions |
| [Getting Started](getting-started.md) | Your first steps with Dotstash |
| [CLI Reference](cli-reference.md) | Complete command documentation |
| [App Guide](app-guide.md) | SwiftUI app walkthrough |
| [Safety Features](safety.md) | How Dotstash protects your files |
| [Contributing](contributing.md) | How to contribute |

---

## 🎯 Example Usage

### Stash and Link

```bash
# Add your dotfiles
dotstash add .zshrc
dotstash add .gitconfig
dotstash add .config/nvim

# Link them back to home
dotstash link

# Check status
dotstash status
```

### Export and Import

```bash
# Export to Desktop
dotstash export
# 📦 Exported to: ~/Desktop/dotstash-export-2026-08-22.tar.gz

# On new machine, import
dotstash import ~/Desktop/dotstash-export-2026-08-22.tar.gz
# 📥 Imported 3 file(s) from archive

# Link everything
dotstash link
```

---

## 🛡️ Safety

Dotstash protects your files with:

- **Drift Detection**: Detects modified files before overwriting
- **Diff-and-Refuse**: Shows options when conflicts are detected
- **Namespaced Paths**: Avoids basename collisions
- **Content Hashing**: SHA-256 tracks file state

[Learn more about safety features →](safety.md)

---

## 🤝 Community

- [GitHub Discussions](https://github.com/perigrino/dotstash/discussions) - Ask questions
- [Issue Tracker](https://github.com/perigrino/dotstash/issues) - Report bugs
- [Contributing Guide](contributing.md) - Help improve Dotstash

---

## 📄 License

MIT License - see [LICENSE](https://github.com/perigrino/dotstash/blob/main/LICENSE) for details.

---

**Made with ❤️ for macOS**
