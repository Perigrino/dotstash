# 🔒 Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | ✅ Yes             |
| < 2.0   | ❌ No              |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in Dotstash, please report it responsibly.

### 🚨 Critical Vulnerabilities

For critical vulnerabilities that could lead to:

- **Data loss** of dotfiles
- **Unauthorized access** to user systems
- **Code execution** through malicious input
- **Symlink attacks** that could overwrite system files

**Please report immediately via email:**

📧 security@perigrino.dev

**DO NOT** open a public GitHub issue for security vulnerabilities.

### 🛡️ What to Include

When reporting a vulnerability, please include:

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** assessment
4. **Suggested fix** (if any)
5. **Your contact information** for follow-up

### ⏱️ Response Timeline

| Action | Timeframe |
|--------|-----------|
| Acknowledgment | Within 24 hours |
| Initial assessment | Within 72 hours |
| Fix development | 1-7 days (depending on severity) |
| Public disclosure | After fix is released |

### 🏆 Recognition

We appreciate security researchers who report vulnerabilities responsibly:

- **Hall of Fame**: Public recognition (with permission)
- **Credit**: Mentioned in release notes
- **Swag**: Dotstash stickers (for significant findings)

## Security Features

### 🛡️ Built-in Protections

Dotstash includes several security features:

#### 1. **Drift Detection**
- Content hashing (SHA-256) detects file modifications
- Prevents accidental overwrites of user changes
- Refuses to link modified files without explicit `--force`

#### 2. **Safe Symlinks**
- Validates paths before creating symlinks
- Prevents path traversal attacks
- Uses absolute paths to avoid ambiguity

#### 3. **Namespace Isolation**
- Files stored with unique keys to avoid collisions
- Prevents overwriting unrelated files
- Clear separation between stashed and live files

#### 4. **Input Validation**
- Sanitizes file paths
- Validates file existence before operations
- Prevents directory traversal

### ⚠️ Known Limitations

1. **No encryption**: Dotfiles are stored in plain text in `~/.dotstash/`
2. **No access control**: Any user on the system can access the stash
3. **Local only**: No network features, no remote code execution
4. **User responsibility**: Users must ensure their dotfiles don't contain secrets

### 🔐 Best Practices

#### For Users

1. **Don't stash sensitive files** containing:
   - API keys
   - Passwords
   - SSH private keys
   - Certificates

2. **Use secure permissions**:
   ```bash
   chmod 700 ~/.dotstash
   chmod 600 ~/.dotstash/*
   ```

3. **Enable FileVault** on macOS for disk encryption

4. **Review stashed files** regularly

#### For Contributors

1. **Never log sensitive data**
2. **Validate all inputs**
3. **Use secure coding practices**
4. **Review symlink operations carefully**
5. **Test for path traversal vulnerabilities**

## 🛠️ Security Hardening

### File Permissions

After installation, secure your Dotstash directory:

```bash
# Set restrictive permissions
chmod 700 ~/.dotstash
chmod 600 ~/.dotstash/*

# Verify permissions
ls -la ~/.dotstash
```

### Exclude Sensitive Files

Don't stash files containing secrets:

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

### Use Git Ignoring

If using git-backed storage, ensure `.gitignore` excludes sensitive files:

```gitignore
# .gitignore in your dotfiles repo
*.pem
*.key
.env
.env.local
credentials.json
service-account.json
```

## 🔄 Security Updates

### Update Policy

- **Critical vulnerabilities**: Patched immediately
- **High severity**: Patched within 7 days
- **Medium severity**: Patched in next minor release
- **Low severity**: Patched in next major release

### How to Update

#### DMG Installation
1. Download latest release from GitHub
2. Replace existing app in Applications
3. Restart Dotstash

#### CLI Installation
```bash
cd dotstash
git pull origin main
npm install
npm link
```

### Auto-Updates

Dotstash supports automatic updates via Sparkle:

- Checks daily for updates (configurable)
- Downloads and installs automatically
- Requires user confirmation for installation

## 📋 Security Checklist

Before each release, verify:

- [ ] No sensitive data in logs
- [ ] Input validation is complete
- [ ] Symlink operations are safe
- [ ] File permissions are correct
- [ ] Dependencies are up to date
- [ ] No known vulnerabilities in dependencies

## 🔗 Security Resources

- [OWASP Symlink Security](https://owasp.org/www-community/attacks/Link_Traversal)
- [macOS Security Guide](https://support.apple.com/guide/security/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)

## 📞 Contact

For security inquiries:

- **Email**: security@perigrino.dev
- **GitHub**: [@perigrino](https://github.com/perigrino)

For general questions:

- **GitHub Issues**: [dotstash/issues](https://github.com/YOUR_USERNAME/dotstash/issues)
- **Discussions**: [dotstash/discussions](https://github.com/YOUR_USERNAME/dotstash/discussions)

## 📄 License

This security policy is licensed under MIT License.

---

**Last updated**: August 22, 2026

**Version**: 2.0.0
