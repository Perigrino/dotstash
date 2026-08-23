# 📋 Changelog

All notable changes to Dotstash will be documented in this file.

This changelog is automatically updated when new versions are released.

---

## [2.0.1] - 2026-08-23

### 🐛 Bug Fixes

- **Sparkle Updater**: Fixed crash when Sparkle keys are not configured
  - Updater now gracefully disables itself when placeholder keys detected
  - Menu bar shows "Updates not configured" instead of crashing
  - App continues to function normally without auto-updates
- **App Bundle**: Fixed Sparkle framework not being bundled with app
  - Build script now copies Sparkle.framework to Contents/Frameworks/
  - Added rpath for framework loading
- **Menu Bar**: Removed duplicate status bar item
  - Fixed menu bar icon having no actions
  - Removed unused StatusBarController

### 🔧 Improvements

- **Graceful Degradation**: Auto-update feature is now optional
  - App works without Sparkle configuration
  - Clear status indicator in menu bar
  - No error dialogs on launch
- **macOS Compatibility**: Now supports macOS 13 (Ventura) and later
  - Changed minimum deployment target from macOS 14 to macOS 13
  - Updated all documentation and badges

---

## [2.0.0] - 2026-08-22

### 🚀 Features

- **SwiftUI App**: Native macOS menu-bar application
  - Visual dashboard with dotfile cards
  - Diff viewer (unified and side-by-side)
  - Syntax highlighting for config files
  - Drag-and-drop support
  - Live file watching with auto-refresh
  - Menu bar integration with badge count
- **CLI Enhancements**
  - `diff` command for comparing files
  - `export` and `import` for transferring between machines
  - Flexible name lookup (accepts basename, key, or path)
- **Safety Features**
  - Drift detection with SHA-256 content hashing
  - Diff-and-refuse on `link()` (requires `--force`)
  - Namespaced paths to avoid basename collisions
  - Version tracking in config

### 🛡️ Safety Improvements

- **Drift Detection**: Prevents overwriting modified files
- **Diff-and-Refuse**: Shows options when conflicts are detected
- **Namespaced Paths**: Avoids basename collisions
- **Content Hashing**: SHA-256 tracks file state

### 📦 Installation

- DMG installer for easy installation
- CLI via npm
- Build from source

### ⚙️ Auto-Update

- Sparkle framework integration
- Configurable update checks (12h/24h/7d)
- Settings window with update preferences

### 📚 Documentation

- GitHub Pages documentation site
- Comprehensive CLI reference
- Safety features guide
- Contributing guidelines

### 🛠️ Infrastructure

- GitHub Actions workflows for CI/CD
- Automated release drafter
- Issue and PR templates
- Security policy

---

## [1.0.0] - 2026-08-20

### 🚀 Initial Release

- Basic CLI for managing dotfiles
- `add`, `link`, `list`, `remove`, `status` commands
- Simple copy-stash to `~/.dotstash/`

---

## Versioning

Dotstash follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

---

## Updating This Changelog

This changelog is automatically updated by GitHub Actions when new releases are published.

To manually update:

1. Edit this file
2. Commit to main branch
3. Changes will be reflected in the documentation

---

**Legend:**

- 🚀 Features
- 🐛 Bug Fixes
- 📚 Documentation
- 🛡️ Security
- ⚡ Performance
- 🔧 Refactoring
- 🧪 Tests
- 🛠️ Infrastructure
- ⚠️ Breaking Changes
