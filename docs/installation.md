---
layout: default
title: Installation
---

# 📦 Installation

Dotstash can be installed via DMG installer or CLI.

---

## Option 1: DMG Installer (Recommended)

### Download

Download the latest release from [GitHub Releases](https://github.com/perigrino/dotstash/releases/latest).

### Install

1. **Open** the DMG file
2. **Drag** Dotstash to your Applications folder
3. **Launch** Dotstash from Applications

### First Launch

Since Dotstash is not notarized by Apple, you may need to bypass Gatekeeper:

**Method 1: Right-click Open**
1. Right-click on Dotstash in Applications
2. Select "Open"
3. Click "Open" in the dialog

**Method 2: System Settings**
1. Open System Settings → Privacy & Security
2. Scroll down to "Security"
3. Click "Open Anyway" next to Dotstash

---

## Option 2: CLI Only

### Prerequisites

- macOS 10.15+
- Node.js 18+
- Git

### Install Node.js

If you don't have Node.js installed:

```bash
# Using Homebrew
brew install node

# Or download from https://nodejs.org
```

### Clone and Install

```bash
# Clone the repository
git clone https://github.com/perigrino/dotstash.git

# Navigate to the directory
cd dotstash

# Install dependencies
npm install

# Link globally
npm link

# Verify installation
dotstash --version
```

### Update

To update to the latest version:

```bash
cd dotstash
git pull origin main
npm install
npm link
```

---

## Option 3: Build from Source

### Prerequisites

- macOS 14.0+
- Xcode 15.0+ or Swift 6.0+
- Node.js 18+

### Build the App

```bash
# Clone the repository
git clone https://github.com/perigrino/dotstash.git
cd dotstash

# Build the Swift app
cd SwiftApp
swift build -c release

# Create app bundle
cd ..
./scripts/build.sh
```

### Build the CLI

```bash
# Install dependencies
npm install

# Link globally
npm link
```

---

## Verify Installation

### CLI

```bash
dotstash --version
# 2.0.0

dotstash --help
# 📦 Dotstash — a smart dotfiles manager
```

### App

1. Launch Dotstash from Applications
2. Look for the tray icon in your menu bar
3. Click the icon to open the menu

---

## System Requirements

| Requirement | Minimum |
|-------------|---------|
| macOS | 14.0 (Sonoma) |
| Disk Space | 50 MB |
| RAM | 100 MB |

---

## Uninstall

### DMG Installation

```bash
# Remove the app
rm -rf /Applications/Dotstash.app

# Remove preferences
defaults delete com.perigrino.dotstash

# Remove stashed dotfiles (optional)
rm -rf ~/.dotstash
```

### CLI Installation

```bash
# Remove global link
npm uninstall -g dotstash

# Remove repository
rm -rf dotstash

# Remove stashed dotfiles (optional)
rm -rf ~/.dotstash
```

---

## Troubleshooting

### "App is damaged" Error

This is a Gatekeeper issue. Run:

```bash
xattr -cr /Applications/Dotstash.app
```

### Permission Denied

Make sure you have write permissions:

```bash
chmod +x /Applications/Dotstash.app/Contents/MacOS/Dotstash
```

### CLI Not Found

Make sure npm global bin is in your PATH:

```bash
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Next Steps

- [Getting Started](getting-started.md) - Your first steps
- [CLI Reference](cli-reference.md) - Command documentation
- [App Guide](app-guide.md) - App walkthrough
