# 🏗️ Dotstash Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DOTSTASH SYSTEM                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         USER INTERFACE                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │   SwiftUI    │  │     CLI      │  │  Menu Bar    │             │   │
│  │  │     App      │  │   (Node.js)  │  │   Icon       │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │  • Dashboard │  │  • add       │  │  • Badge     │             │   │
│  │  │  • Diff View │  │  • link      │  │  • Quick     │             │   │
│  │  │  • Settings  │  │  • list      │  │    Actions   │             │   │
│  │  │  • Drag&Drop │  │  • diff      │  │  • Status    │             │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │   │
│  │         │                 │                 │                      │   │
│  └─────────┼─────────────────┼─────────────────┼──────────────────────┘   │
│            │                 │                 │                           │
│            ▼                 ▼                 ▼                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                       CORE ENGINE                                   │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    DotstashManager                           │   │   │
│  │  │  • Config management (read/write dotstash.json)             │   │   │
│  │  │  • File operations (copy, symlink, remove)                  │   │   │
│  │  │  • Drift detection (SHA-256 hashing)                        │   │   │
│  │  │  • Export/Import (tar.gz archives)                          │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ FileWatcher  │  │  DiffEngine  │  │  SyntaxHL    │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │ • GCD Source │  │ • LCS algo   │  │ • Shell      │             │   │
│  │  │ • File events│  │ • Unified    │  │ • JSON       │             │   │
│  │  │ • Auto-refresh│ │ • Side-by-side│ │ • YAML       │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│            │                 │                 │                           │
│            ▼                 ▼                 ▼                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      STORAGE LAYER                                  │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    ~/.dotstash/                               │   │   │
│  │  │  ├── dotstash.json          (config & metadata)             │   │   │
│  │  │  ├── zshrc                   (stashed files)                │   │   │
│  │  │  ├── gitconfig                                            │   │   │
│  │  │  ├── config-nvim-init.vim   (namespaced paths)              │   │   │
│  │  │  └── ...                                                   │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    $HOME/ (symlinks)                         │   │   │
│  │  │  ~/.zshrc ──────────────────────> ~/.dotstash/zshrc         │   │   │
│  │  │  ~/.gitconfig ──────────────────> ~/.dotstash/gitconfig     │   │   │
│  │  │  ~/.config/nvim ───────────────> ~/.dotstash/config-nvim    │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SWIFTUI APPLICATION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         App Lifecycle                                │   │
│  │  DotstashApp.swift                                                  │   │
│  │  ├── @main App struct                                               │   │
│  │  ├── WindowGroup (main dashboard)                                   │   │
│  │  ├── MenuBarExtra (menu bar icon)                                   │   │
│  │  └── Settings (preferences window)                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                  │                                          │
│                                  ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Views Layer                                  │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ ContentView  │  │ MenuBarView  │  │ SettingsView │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │ • Navigation │  │ • Quick      │  │ • General    │             │   │
│  │  │ • Sidebar    │  │   Actions    │  │ • Updates    │             │   │
│  │  │ • Grid View  │  │ • Status     │  │ • About      │             │   │
│  │  │ • Drag&Drop  │  │ • Export     │  │              │             │   │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘             │   │
│  │         │                                                          │   │
│  │         ▼                                                          │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    Sub-Views                                 │   │   │
│  │  │  • DotfileGridView     • DotfileDetailSheet                 │   │   │
│  │  │  • DiffViewer          • AddDotfileSheet                    │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                  │                                          │
│                                  ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Models Layer                                  │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ Dotstash     │  │ Dotfile      │  │ FileWatcher  │             │   │
│  │  │ Manager      │  │ Model        │  │              │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │ • Config I/O │  │ • Codable    │  │ • GCD        │             │   │
│  │  │ • Operations │  │ • Health     │  │ • Dispatch   │             │   │
│  │  │ • Drift      │  │ • DiffType   │  │ • Sources    │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ Syntax       │  │ Updater      │  │ Status       │             │   │
│  │  │ Highlighter  │  │ Controller   │  │ Bar          │             │   │
│  │  │              │  │              │  │ Controller   │             │   │
│  │  │ • Shell      │  │ • Sparkle    │  │              │             │   │
│  │  │ • JSON       │  │ • Version    │  │ • Badge      │             │   │
│  │  │ • YAML       │  │ • Check      │  │ • Icon       │             │   │
│  │  │ • TOML       │  │              │  │              │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA FLOW DIAGRAM                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  USER ACTION                                                                │
│      │                                                                      │
│      ▼                                                                      │
│  ┌─────────────┐                                                            │
│  │  UI Event   │                                                            │
│  │  (Click/    │                                                            │
│  │   Drag)     │                                                            │
│  └──────┬──────┘                                                            │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    1. INPUT PROCESSING                              │   │
│  │                                                                     │   │
│  │  SwiftUI View ──> Action Handler ──> Manager Method                 │   │
│  │                                                                     │   │
│  │  Example:                                                          │   │
│  │  User clicks "Add" → AddDotfileSheet → manager.addDotfile(path)    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    2. VALIDATION                                    │   │
│  │                                                                     │   │
│  │  • Path validation (exists? accessible?)                           │   │
│  │  • Type detection (file? directory?)                               │   │
│  │  • Permission check (readable? writable?)                          │   │
│  │                                                                     │   │
│  │  Example:                                                          │   │
│  │  guard FileManager.default.fileExists(atPath: path) else {         │   │
│  │      errorMessage = "File not found"                               │   │
│  │      return                                                        │   │
│  │  }                                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    3. CORE OPERATIONS                               │   │
│  │                                                                     │   │
│  │  ┌─────────────────┐    ┌─────────────────┐                        │   │
│  │  │    ADD FILE     │    │   LINK FILE     │                        │   │
│  │  │                 │    │                 │                        │   │
│  │  │ 1. Copy to      │    │ 1. Check drift  │                        │   │
│  │  │    ~/.dotstash/ │    │    (SHA-256)    │                        │   │
│  │  │ 2. Update config│    │ 2. If modified: │                        │   │
│  │  │ 3. Return path  │    │    REFUSE       │                        │   │
│  │  │                 │    │ 3. Else:        │                        │   │
│  │  │                 │    │    Symlink      │                        │   │
│  │  └────────┬────────┘    └────────┬────────┘                        │   │
│  │           │                      │                                 │   │
│  │           ▼                      ▼                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    FILE OPERATIONS                          │   │   │
│  │  │                                                             │   │   │
│  │  │  • copyItem()     • symlinkSync()    • removeItem()        │   │   │
│  │  │  • contents()     • attributes()     • createSymbolicLink()│   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    4. PERSISTENCE                                   │   │
│  │                                                                     │   │
│  │  ┌─────────────────┐    ┌─────────────────┐                        │   │
│  │  │  Config File    │    │  Stash Directory │                        │   │
│  │  │                 │    │                 │                        │   │
│  │  │ dotstash.json   │    │ ~/.dotstash/   │                        │   │
│  │  │ {               │    │ ├── file1      │                        │   │
│  │  │   "dotfiles": { │    │ ├── file2      │                        │   │
│  │  │     "key": {    │    │ └── ...        │                        │   │
│  │  │       ...       │    │                 │                        │   │
│  │  │     }           │    │                 │                        │   │
│  │  │   }             │    │                 │                        │   │
│  │  │ }               │    │                 │                        │   │
│  │  └─────────────────┘    └─────────────────┘                        │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    5. UI UPDATE                                     │   │
│  │                                                                     │   │
│  │  @Published properties ──> SwiftUI re-renders                     │   │
│  │                                                                     │   │
│  │  • dotfiles array updated                                          │   │
│  │  • Success/error messages displayed                                │   │
│  │  • Badge count updated                                             │   │
│  │  • File watcher restarted                                          │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SECURITY LAYERS                                  │   │
│  │                                                                     │   │
│  │  Layer 1: INPUT VALIDATION                                          │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │  • Path sanitization                                        │   │   │
│  │  │  • File existence checks                                    │   │   │
│  │  │  • Permission verification                                  │   │   │
│  │  │  • Type validation (file/dir)                               │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Layer 2: DRIFT DETECTION                                           │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │  • SHA-256 content hashing                                  │   │   │
│  │  │  • Hash comparison on link                                  │   │   │
│  │  │  • Refuse if modified (unless --force)                      │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Layer 3: SAFETY CHECKS                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │  • Diff-and-refuse on link()                                │   │   │
│  │  │  • Confirmation dialogs                                     │   │   │
│  │  │  • Backup before overwrite                                  │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Layer 4: FILE SYSTEM SECURITY                                      │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │  • Restrictive permissions (700/600)                        │   │   │
│  │  │  • Namespaced paths (avoid collisions)                      │   │   │
│  │  │  • No encryption (plain text storage)                       │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SECURITY FLOW                                    │   │
│  │                                                                     │   │
│  │  User Action ──> Input Validation ──> Drift Check ──> Operation    │   │
│  │       │              │                    │              │          │   │
│  │       │              ▼                    ▼              ▼          │   │
│  │       │         Reject if              Refuse if     Execute if    │   │
│  │       │         invalid                modified      safe          │   │
│  │       │              │                    │              │          │   │
│  │       └──────────────┴────────────────────┴──────────────┘          │   │
│  │                              │                                      │   │
│  │                              ▼                                      │   │
│  │                     Log & Report                                    │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## File Structure

```
Dotstash/
│
├── 📄 README.md                    # Project documentation
├── 📄 CHANGELOG.md                 # Version history
├── 📄 CONTRIBUTING.md              # Contributor guide
├── 📄 SECURITY.md                  # Security policy
├── 📄 LICENSE                      # MIT license
├── 📄 PRODUCT-BRIEF.md             # Product analysis
├── 📄 ARCHITECTURE.md              # This file
│
├── 📁 SwiftApp/                    # SwiftUI macOS App
│   ├── 📄 Package.swift            # Swift dependencies (Sparkle)
│   ├── 📄 appcast.xml              # Sparkle update feed
│   │
│   └── 📁 Sources/DotstashApp/
│       ├── 📄 DotstashApp.swift    # App entry point (@main)
│       │
│       ├── 📁 Models/
│       │   ├── 📄 Dotfile.swift         # Data models (DotfileEntry, Config)
│       │   ├── 📄 DotstashManager.swift  # Core business logic
│       │   ├── 📄 FileWatcher.swift      # GCD file monitoring
│       │   ├── 📄 SyntaxHighlighter.swift # Syntax highlighting engine
│       │   ├── 📄 UpdaterController.swift # Sparkle integration
│       │   └── 📄 StatusBarController.swift # Menu bar badge
│       │
│       └── 📁 Views/
│           ├── 📄 ContentView.swift      # Main dashboard view
│           ├── 📄 MenuBarView.swift      # Menu bar popover
│           ├── 📄 DotfileGridView.swift  # Grid of dotfile cards
│           ├── 📄 DotfileDetailSheet.swift # Detail/modal view
│           ├── 📄 DiffViewer.swift       # Unified/side-by-side diff
│           ├── 📄 AddDotfileSheet.swift   # Add file dialog
│           └── 📄 SettingsView.swift     # App preferences
│
├── 📁 lib/                         # Core CLI Engine (Node.js)
│   └── 📄 dotstash.js              # All CLI logic (stash, link, diff, etc.)
│
├── 📁 src/                         # CLI Entry Points
│   ├── 📄 cli.js                   # Command-line interface
│   └── 📄 index.js                 # Public API
│
├── 📁 scripts/                     # Build & Release Scripts
│   ├── 📄 build.sh                 # Build .app + DMG
│   ├── 📄 release.sh               # GitHub release via gh CLI
│   ├── 📄 bump-version.sh          # Version bumping
│   └── 📄 security-audit.sh        # Security audit
│
├── 📁 docs/                        # GitHub Pages Documentation
│   ├── 📄 _config.yml              # Jekyll configuration
│   ├── 📄 index.md                 # Homepage
│   ├── 📄 installation.md          # Installation guide
│   ├── 📄 cli-reference.md         # CLI documentation
│   └── 📄 safety.md                # Safety features
│
├── 📁 build/                       # Build Artifacts
│   ├── 📁 Dotstash.app/            # macOS app bundle
│   └── 📄 Dotstash-2.0.0.dmg      # Installer disk image
│
└── 📁 .github/                     # GitHub Configuration
    ├── 📁 workflows/
    │   ├── 📄 release.yml          # Build & release
    │   ├── 📄 codeql.yml           # Security scanning
    │   ├── 📄 dependency-review.yml # Dependency audit
    │   ├── 📄 labeler.yml          # Issue labeling
    │   ├── 📄 pr-labeler.yml       # PR labeling
    │   ├── 📄 stale.yml            # Stale issue management
    │   ├── 📄 release-drafter.yml  # Release notes
    │   ├── 📄 update-changelog.yml # Changelog updates
    │   ├── 📄 docs.yml             # GitHub Pages deploy
    │   └── 📄 welcome.yml          # New contributor welcome
    │
    ├── 📁 ISSUE_TEMPLATE/
    │   ├── 📄 bug_report.md
    │   └── 📄 feature_request.md
    │
    ├── 📄 dependabot.yml           # Dependabot config
    └── 📄 release-drafter.yml      # Release drafter config
```

## Technology Stack

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TECHNOLOGY STACK                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    FRONTEND / UI                                    │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │   SwiftUI    │  │   MenuBar    │  │   Diff       │             │   │
│  │  │   (macOS)    │  │   Extra      │  │   Viewer     │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │  • Views     │  │  • Menu Bar  │  │  • Unified   │             │   │
│  │  │  • State     │  │  • Badge     │  │  • Side-by-  │             │   │
│  │  │  • Binding   │  │  • Popover   │  │    side      │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    BACKEND / LOGIC                                   │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │   Swift 6    │  │   Node.js    │  │   Sparkle    │             │   │
│  │  │              │  │   18+        │  │   Framework  │             │   │
│  │  │  • Async/    │  │              │  │              │             │   │
│  │  │    Await     │  │  • CLI       │  │  • Auto-     │             │   │
│  │  │  • Actors    │  │  • Scripts   │  │    update    │             │   │
│  │  │  • SwiftUI   │  │  • npm       │  │  • Signing   │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    STORAGE / DATA                                   │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │   JSON       │  │   File       │  │   SHA-256    │             │   │
│  │  │   Config     │  │   System     │  │   Hashing    │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │  • Codable   │  │  • Copy      │  │  • Drift     │             │   │
│  │  │  • Encode/   │  │  • Symlink   │  │    detection │             │   │
│  │  │    Decode    │  │  • Watch     │  │  • Integrity │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    INFRASTRUCTURE                                   │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │   GitHub     │  │   GitHub     │  │   GitHub     │             │   │
│  │  │   Actions    │  │   Pages      │  │   Releases   │             │   │
│  │  │              │  │              │  │              │             │   │
│  │  │  • CI/CD     │  │  • Docs      │  │  • DMG       │             │   │
│  │  │  • Testing   │  │  • Jekyll    │  │  • Changelog │             │   │
│  │  │  • Security  │  │  • Search    │  │  • Notes     │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

**Last Updated:** August 22, 2026
