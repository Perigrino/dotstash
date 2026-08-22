---
layout: default
title: Safety Features
---

# 🛡️ Safety Features

Dotstash includes multiple safety features to protect your dotfiles from accidental data loss.

---

## Overview

| Feature | Description |
|---------|-------------|
| 🔍 **Drift Detection** | Detects files modified since last stash |
| 🚫 **Diff-and-Refuse** | Refuses to overwrite modified files |
| 📁 **Namespaced Paths** | Prevents basename collisions |
| 🔐 **Content Hashing** | SHA-256 tracks file state |
| ↩️ **Restore** | Recover stashed versions |

---

## Drift Detection

### How It Works

When you stash a file, Dotstash computes a SHA-256 hash of its contents. Before linking, it compares the current hash with the stored hash.

**Flow:**
```
1. dotstash add .zshrc
   → Compute hash: abc123...
   → Store in config

2. User edits .zshrc
   → File contents change
   → Hash would be different

3. dotstash link .zshrc
   → Compute current hash: def456...
   → Compare with stored: abc123...
   → Mismatch detected!
   → REFUSE to link
```

### Example

```bash
# Stash a file
dotstash add .zshrc
✅ Stashed: .zshrc

# Link it
dotstash link .zshrc
🔗 Linked: /Users/you/.zshrc → /Users/you/.dotstash/zshrc

# Modify the file
echo "# new comment" >> ~/.zshrc

# Try to link again
dotstash link .zshrc
⚠️  REFUSED: .zshrc has been modified since last stash.
   file has been modified since last stash
```

---

## Diff-and-Refuse

When drift is detected, Dotstash refuses to overwrite and provides options:

```
⚠️  REFUSED: .zshrc has been modified since last stash.
   file has been modified since last stash

   Options:
     1. Re-stash the current version:  dotstash add /Users/you/.zshrc
     2. Force overwrite with stashed:  dotstash link .zshrc --force
     3. View differences:              dotstash diff .zshrc
```

### Options Explained

| Option | Command | Result |
|--------|---------|--------|
| Keep current | `dotstash add .zshrc` | Updates stash with current version |
| Force overwrite | `dotstash link .zshrc --force` | Overwrites current with stashed |
| View diff | `dotstash diff .zshrc` | Shows what changed |

### Force Mode

Use `--force` only when you're sure you want to overwrite:

```bash
dotstash link .zshrc --force
⚠️  Force mode: overwriting modified file.
🔗 Linked: /Users/you/.zshrc → /Users/you/.dotstash/zshrc
```

---

## Namespaced Paths

### The Problem

Without namespacing, two files with the same name would collide:

```
~/.zshrc
~/.config/zsh/zshrc
```

Both would map to `zshrc` in the stash, overwriting each other.

### The Solution

Dotstash uses the source path to create unique keys:

```
~/.zshrc              → zshrc
~/.config/zsh/zshrc   → config-zsh-zshrc
```

### Example

```bash
# Add two files with similar names
dotstash add ~/.zshrc
dotstash add ~/.config/zsh/zshrc

# Both are stored separately
dotstash list
✅ .zshrc
   Stashed: ~/.dotstash/zshrc

✅ zshrc
   Stashed: ~/.dotstash/config-zsh-zshrc
```

---

## Content Hashing

### Algorithm

Dotstash uses SHA-256 for content hashing:

```javascript
const crypto = require('crypto');

function contentHash(filePath) {
  const data = fs.readFileSync(filePath);
  return crypto.createHash('sha256')
    .update(data)
    .digest('hex')
    .slice(0, 16);
}
```

### What's Hashed

- File contents (for regular files)
- Directory contents (recursively)

### What's Not Hashed

- File permissions
- File timestamps
- Symbolic links (target is checked separately)

---

## Restore

If you accidentally overwrote a file, you can restore from the stash:

### Via App

1. Open Dotstash
2. Click on the dotfile card
3. Click "Restore from Stash"

### Via CLI

```bash
# Copy stashed version back
cp ~/.dotstash/zshrc ~/.zshrc

# Or re-stash and link
dotstash link .zshrc --force
```

---

## Path Traversal Protection

Dotstash validates paths to prevent directory traversal attacks:

```bash
# These are rejected
dotstash add ../../../etc/passwd
dotstash add ~../../.ssh/id_rsa

# These are accepted
dotstash add ~/.zshrc
dotstash add /Users/you/.gitconfig
```

---

## File Permission Recommendations

After installation, secure your Dotstash directory:

```bash
# Set restrictive permissions
chmod 700 ~/.dotstash
chmod 600 ~/.dotstash/*

# Verify
ls -la ~/.dotstash
drwx------  3 you  staff   96 Aug 22 10:00 .
-rw-------  1 you  staff  123 Aug 22 10:00 dotstash.json
-rw-------  1 you  staff  456 Aug 22 10:00 zshrc
```

---

## What's NOT Protected

### Sensitive Files

Dotstash does **not** encrypt or protect sensitive files:

```bash
# ❌ DON'T stash these
dotstash add ~/.ssh/id_rsa
dotstash add ~/.aws/credentials
dotstash add ~/.env

# ✅ SAFE to stash
dotstash add ~/.zshrc
dotstash add ~/.gitconfig
dotstash add ~/.vimrc
```

### Network Security

Dotstash has no network features:
- No remote sync
- No cloud storage
- No API calls

### Access Control

Any user on the system can access `~/.dotstash/` if they have file permissions.

---

## Best Practices

### 1. Regular Backups

Even with Dotstash, backup your dotfiles:

```bash
# Export regularly
dotstash export

# Keep exports in a safe location
mv ~/Desktop/dotstash-export-*.tar.gz ~/Backups/
```

### 2. Review Before Force

Always review changes before forcing:

```bash
# See what changed
dotstash diff .zshrc

# Then decide
dotstash link .zshrc --force  # If you want stashed version
# OR
dotstash add .zshrc  # If you want current version
```

### 3. Use Version Control

Store your Dotstash exports in a private git repo:

```bash
# Create a private repo
git init dotstash-backup
cd dotstash-backup

# Export and commit
dotstash export
cp ~/Desktop/dotstash-export-*.tar.gz .
git add .
git commit -m "Backup dotfiles"
git remote add origin git@github.com:you/dotstash-backup.git
git push
```

### 4. Don't Stash Secrets

Use a password manager for secrets, not Dotstash.

---

## Security Checklist

Before each release:

- [ ] No sensitive data in logs
- [ ] Input validation is complete
- [ ] Symlink operations are safe
- [ ] File permissions are correct
- [ ] Dependencies are up to date

---

## Reporting Vulnerabilities

If you discover a security vulnerability, please report it responsibly:

📧 security@perigrino.dev

See [SECURITY.md](https://github.com/perigrino/dotstash/blob/main/SECURITY.md) for details.

---

## Next Steps

- [CLI Reference](cli-reference.md) - Command documentation
- [App Guide](app-guide.md) - App walkthrough
