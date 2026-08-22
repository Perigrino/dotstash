# 📋 Changelog

All notable changes to Dotstash will be documented in this file.

This changelog is automatically updated when new versions are released.

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
