# 📦 Dotstash

**A native macOS dotfiles manager** — stash, link, and restore your configs with a beautiful SwiftUI app or powerful CLI.

[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Security](https://img.shields.io/badge/Security-Policy-red)](SECURITY.md)
[![OpenSSF Scorecard](https://img.shields.io/badge/OpenSSF-Scorecard-blue)](https://securityscorecards.dev)
[![Dependabot](https://img.shields.io/badge/Dependabot-Enabled-blue)](https://github.com/dependabot)
[![Code Scanning](https://img.shields.io/badge/Code%20Scanning-Enabled-brightgreen)](https://codeql.github.com)

---

## 🚀 Installation

### Option 1: DMG Installer (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotstash.git
   cd dotstash
   ```

2. **Build the DMG:**
   ```bash
   ./scripts/build.sh
   ```

3. **Install the app:**
   ```bash
   open build/Dotstash-1.0.0.dmg
   ```

4. **Drag** Dotstash to your Applications folder

5. **Launch** Dotstash from Applications

> ⚠️ **First launch:** Since Dotstash is not notarized by Apple, you may need to:
> - Right-click → Open (first time only)
> - Or go to **System Settings → Privacy & Security → Open Anyway**

### Option 2: CLI Only

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotstash.git
cd dotstash

# Install dependencies
npm install

# Link globally
npm link

# Verify installation
dotstash --version
```

---

## 📱 The App

Dotstash is a **native macOS menu-bar app** built with SwiftUI. It provides a beautiful interface for managing your dotfiles.

### Features

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
| ⚙️ **Auto-Update** | Sparkle-powered updates (when configured) |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘,` | Open Settings |
| `⌘N` | Add new dotfile |
| `⌘⇧L` | Link all dotfiles |
| `⌘⇧E` | Export stash |

---

## 💻 The CLI

The CLI provides powerful command-line access to all Dotstash features.

### Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `dotstash add <file>` | — | Stash a dotfile |
| `dotstash list` | `dotstash ls` | List stashed dotfiles |
| `dotstash link [name]` | — | Symlink (one or all) |
| `dotstash diff <name>` | — | Show differences |
| `dotstash remove <name>` | `dotstash rm` | Untrack a dotfile |
| `dotstash status` | `dotstash st` | Health check |
| `dotstash export` | — | Export to tarball |
| `dotstash import <archive>` | — | Import from tarball |

### Quick Start

```bash
# Stash a dotfile from your home directory
dotstash add .zshrc

# Stash a directory
dotstash add .config/nvim

# List all stashed dotfiles
dotstash list

# Link a single dotfile back to home
dotstash link .zshrc

# Link all stashed dotfiles at once
dotstash link

# Check the health of your dotfiles
dotstash status

# View differences between stashed and live
dotstash diff .zshrc

# Remove a dotfile from tracking
dotstash remove .zshrc

# Remove and delete the stashed copy
dotstash remove .zshrc --delete

# Export all dotfiles to Desktop
dotstash export

# Import from a tarball
dotstash import ~/Desktop/dotstash-export-*.tar.gz
```

---

## 🛡️ Safety Features

### Drift Detection

Dotstash detects when files have been modified since they were stashed:

```
dotstash link .zshrc
# ⚠️  REFUSED: .zshrc has been modified since last stash.
#    file has been modified since last stash
#
#    Options:
#      1. Re-stash the current version:  dotstash add .zshrc
#      2. Force overwrite with stashed:  dotstash link .zshrc --force
#      3. View differences:              dotstash diff .zshrc
```

### Namespaced Paths

Files are stored with unique names to avoid collisions:

```
~/.zshrc              → ~/.dotstash/zshrc
~/.config/nvim/init.vim → ~/.dotstash/config-nvim-init.vim
```

### Content Hashing

SHA-256 hashes track file state for accurate drift detection.

---

## 🔒 Security

Dotstash takes security seriously. Please review our [Security Policy](SECURITY.md) for details.

### Security Features

- ✅ **Drift Detection**: SHA-256 content hashing
- ✅ **Diff-and-Refuse**: Prevents accidental overwrites
- ✅ **Namespaced Paths**: Avoids basename collisions
- ✅ **Input Validation**: Sanitizes file paths
- ✅ **Secure Permissions**: Recommends restrictive file permissions

### Security Auditing

Run the security audit script:

```bash
./scripts/security-audit.sh
```

### Reporting Vulnerabilities

If you discover a security vulnerability, please report it responsibly:

📧 [security@perigrino.dev](mailto:security@perigrino.dev)

See [SECURITY.md](SECURITY.md) for more information.

---

## 📦 Export/Import

Transfer your dotfiles between machines:

```bash
# Export all dotfiles to Desktop
dotstash export
# 📦 Exported to: ~/Desktop/dotstash-export-2026-08-22.tar.gz

# On new machine, import the archive
dotstash import ~/Desktop/dotstash-export-2026-08-22.tar.gz
# 📥 Imported 5 file(s) from archive

# Link everything
dotstash link
```

---

## ⚙️ Auto-Updates

Dotstash uses [Sparkle](https://sparkle-project.org/) for auto-updates (macOS app only).

### Current Status

> ⚠️ **Auto-updates are disabled by default.** The updater gracefully disables itself when Sparkle keys are not configured. You'll see "Updates not configured" in the menu bar until you set up the keys.

### Enabling Auto-Updates

To enable auto-updates for your distribution:

1. **Generate EdDSA key pair:**
   ```bash
   # Download Sparkle tools
   brew install --cask sparkle

   # Generate keys
   generate_keys
   ```

2. **Update Info.plist:**
   - Replace `YOUR_SPARKLE_PUBLIC_KEY_HERE` with your public key
   - Replace `YOUR_USERNAME` in the feed URL

3. **Host appcast.xml:**
   - Update `YOUR_USERNAME` in `appcast.xml`
   - Host on GitHub or your server

4. **Sign releases:**
   ```bash
   sign_update Dotstash-2.0.1.dmg
   ```

### Behavior Without Keys

When Sparkle keys are not configured:
- The updater is automatically disabled
- "Updates not configured" appears in the menu bar
- The app functions normally otherwise
- No error messages or crashes

---

## 🏗️ Building from Source

### Prerequisites

- macOS 13.0+
- Xcode 15.0+ or Swift 6.0+
- Node.js 18+ (for CLI)

### Build the App

```bash
cd SwiftApp
swift build -c release
```

### Build the CLI

```bash
npm install
npm link
```

### Create DMG

```bash
# Build release
cd SwiftApp && swift build -c release

# Create .app bundle
cd ..
mkdir -p build/Dotstash.app/Contents/{MacOS,Resources}
cp SwiftApp/.build/release/DotstashApp build/Dotstash.app/Contents/MacOS/Dotstash
# ... (see full build script in project)

# Create DMG
hdiutil create -volname "Dotstash" -srcfolder build/ -ov -format UDZO build/Dotstash-1.0.0.dmg
```

---

## 📁 Project Structure

```
Dotstash/
├── README.md                    # This file
├── PRODUCT-BRIEF.md             # Product analysis
├── lib/
│   └── dotstash.js              # Core CLI engine
├── src/
│   ├── cli.js                   # CLI interface
│   └── index.js                 # Public API
├── SwiftApp/
│   ├── Package.swift            # Swift dependencies
│   ├── appcast.xml              # Sparkle update feed
│   └── Sources/DotstashApp/
│       ├── DotstashApp.swift    # App entry point
│       ├── Models/
│       │   ├── Dotfile.swift
│       │   ├── DotstashManager.swift
│       │   ├── FileWatcher.swift
│       │   ├── StatusBarController.swift
│       │   ├── SyntaxHighlighter.swift
│       │   └── UpdaterController.swift
│       └── Views/
│           ├── ContentView.swift
│           ├── MenuBarView.swift
│           ├── DotfileGridView.swift
│           ├── DotfileDetailSheet.swift
│           ├── DiffViewer.swift
│           ├── AddDotfileSheet.swift
│           └── SettingsView.swift
├── build/
│   ├── Dotstash.app/            # Built app bundle
│   └── Dotstash-1.0.0.dmg      # Installer
└── package.json
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Sparkle](https://sparkle-project.org/) - Auto-update framework
- [Commander.js](https://github.com/tj/commander.js) - CLI framework
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Native macOS UI

---

**Built with ❤️ for macOS**
