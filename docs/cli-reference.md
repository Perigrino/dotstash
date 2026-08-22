---
layout: default
title: CLI Reference
---

# 💻 CLI Reference

Complete documentation for the Dotstash command-line interface.

---

## Global Options

| Option | Description |
|--------|-------------|
| `-V, --version` | Output the version number |
| `-h, --help` | Display help for command |

---

## Commands

### `dotstash add <file>`

Stash a dotfile from your home directory.

**Usage:**
```bash
dotstash add <file>
```

**Examples:**
```bash
# Add a single file
dotstash add .zshrc

# Add a directory
dotstash add .config/nvim

# Add with absolute path
dotstash add /Users/you/.gitconfig
```

**Output:**
```
📦 Stashing dotfile...

✅ Stashed: .zshrc
   /Users/you/.zshrc → /Users/you/.dotstash/zshrc
```

---

### `dotstash list`

List all stashed dotfiles.

**Aliases:** `dotstash ls`

**Usage:**
```bash
dotstash list
```

**Output:**
```
📦 Stashed dotfiles (3):

✅ .zshrc 🔗
   Source:  /Users/you/.zshrc
   Stashed: /Users/you/.dotstash/zshrc
   Type:    file
   Added:   2026-08-22T10:30:00Z

✅ .gitconfig
   Source:  /Users/you/.gitconfig
   Stashed: /Users/you/.dotstash/gitconfig
   Type:    file
   Added:   2026-08-22T10:31:00Z

✅ .config
   Source:  /Users/you/.config
   Stashed: /Users/you/.dotstash/config
   Type:    directory
   Added:   2026-08-22T10:32:00Z
```

**Legend:**
- ✅ File exists in stash
- ⚠️ File missing from stash
- 🔗 File is symlinked to home

---

### `dotstash link [name]`

Symlink a stashed dotfile back to your home directory.

**Usage:**
```bash
# Link a specific file
dotstash link .zshrc

# Link all files
dotstash link

# Force link (overwrite modifications)
dotstash link .zshrc --force
```

**Safety Features:**

If the target file has been modified since stashing, Dotstash will refuse to overwrite:

```
⚠️  REFUSED: .zshrc has been modified since last stash.
   file has been modified since last stash

   Options:
     1. Re-stash the current version:  dotstash add /Users/you/.zshrc
     2. Force overwrite with stashed:  dotstash link .zshrc --force
     3. View differences:              dotstash diff .zshrc
```

**Options:**

| Option | Description |
|--------|-------------|
| `-f, --force` | Overwrite modified files (dangerous!) |

---

### `dotstash diff <name>`

Show differences between stashed and live versions.

**Usage:**
```bash
dotstash diff .zshrc
```

**Output:**
```
📊 Diff for .zshrc:

--- stashed (/Users/you/.dotstash/zshrc)
+++ live    (/Users/you/.zshrc)

27a28,29
> # test modification
> # test modification
```

---

### `dotstash remove <name>`

Untrack a dotfile.

**Aliases:** `dotstash rm`

**Usage:**
```bash
# Untrack only (keep stashed copy)
dotstash remove .zshrc

# Untrack and delete stashed copy
dotstash remove .zshrc --delete
```

**Options:**

| Option | Description |
|--------|-------------|
| `-d, --delete` | Also delete the stashed copy |

---

### `dotstash status`

Check the health of your stashed dotfiles.

**Aliases:** `dotstash st`

**Usage:**
```bash
dotstash status
```

**Output:**
```
📊 Dotstash Status:

✅ .zshrc — linked and up to date
⚠️  .gitconfig — exists but is NOT symlinked
🔴 .vimrc — MODIFIED since last stash (drift!)

ℹ️  2 item(s) need attention.
```

**Status Icons:**

| Icon | Meaning |
|------|---------|
| ✅ | Linked and up to date |
| ⚡ | Exists but not symlinked |
| 🔴 | Modified since last stash (drift) |
| ⚠️ | Missing from home directory |
| ⚠️ | Stashed copy is missing |

---

### `dotstash export`

Export all stashed dotfiles to a tarball.

**Usage:**
```bash
dotstash export
```

**Output:**
```
📦 Exported to: ~/Desktop/dotstash-export-2026-08-22T10-30-00Z.tar.gz
   Contains 3 dotfile(s)
```

**Use Case:**
Transfer your dotfiles to a new machine.

---

### `dotstash import <archive>`

Import dotfiles from a tarball.

**Usage:**
```bash
dotstash import ~/Desktop/dotstash-export-2026-08-22.tar.gz
```

**Output:**
```
📥 Imported 3 file(s) from archive
```

**Notes:**
- Existing files are overwritten
- Config is auto-rebuilt after import

---

## Configuration

### Config File

Location: `~/.dotstash/dotstash.json`

**Example:**
```json
{
  "dotfiles": {
    "zshrc": {
      "source": "/Users/you/.zshrc",
      "stashed": "/Users/you/.dotstash/zshrc",
      "basename": ".zshrc",
      "stashedAt": "2026-08-22T10:30:00Z",
      "lastSyncedAt": "2026-08-22T10:35:00Z",
      "isDirectory": false,
      "hash": "26f79500d48277f8"
    }
  },
  "created": "2026-08-22T10:00:00Z",
  "version": 2
}
```

### Stash Directory

Location: `~/.dotstash/`

Contents:
```
~/.dotstash/
├── dotstash.json      # Configuration
├── zshrc              # Stashed .zshrc
├── gitconfig          # Stashed .gitconfig
└── config/            # Stashed .config directory
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DOTSTASH_DIR` | Custom stash directory | `~/.dotstash` |

---

## Exit Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | File not found |
| 3 | Operation refused (drift detected) |

---

## Examples

### Complete Workflow

```bash
# 1. Stash your dotfiles
dotstash add .zshrc
dotstash add .gitconfig
dotstash add .vimrc
dotstash add .config/nvim

# 2. Link them back to home
dotstash link

# 3. Check everything is good
dotstash status

# 4. Later, export for backup
dotstash export

# 5. On new machine, import and link
dotstash import ~/Desktop/dotstash-export-*.tar.gz
dotstash link
```

### Troubleshooting Workflow

```bash
# Check status
dotstash status

# If drift detected, view diff
dotstash diff .zshrc

# Either re-stash or force link
dotstash add .zshrc  # Keep current version
# OR
dotstash link .zshrc --force  # Overwrite with stashed
```

---

## Next Steps

- [App Guide](app-guide.md) - SwiftUI app walkthrough
- [Safety Features](safety.md) - How Dotstash protects your files
