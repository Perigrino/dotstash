# 🤝 Contributing to Dotstash

Thank you for your interest in contributing to Dotstash! This document provides guidelines and information about contributing.

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+
- Xcode 15.0+ or Swift 6.0+
- Node.js 18+ (for CLI)
- Git

### Fork & Clone

```bash
# Fork the repository on GitHub, then clone
git clone https://github.com/YOUR_USERNAME/dotstash.git
cd dotstash

# Add upstream remote
git remote add upstream https://github.com/YOUR_USERNAME/dotstash.git
```

### Development Setup

```bash
# Install CLI dependencies
npm install

# Build Swift app (development mode)
cd SwiftApp
swift build

# Link CLI globally (for testing)
cd ..
npm link
```

## 📝 Development Guidelines

### Code Style

**Swift:**
- Follow Swift API Design Guidelines
- Use `swiftformat` for consistent formatting
- Add documentation comments for public APIs

**JavaScript:**
- Use ESLint and Prettier
- Follow Node.js style guide
- Add JSDoc comments for functions

### Commit Messages

Use clear, descriptive commit messages:

```
feat: Add new diff viewer feature
fix: Resolve link() data loss issue
docs: Update README with installation guide
refactor: Simplify DotstashManager
test: Add unit tests for drift detection
```

**Prefixes:**
- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation
- `refactor:` — Code refactoring
- `test:` — Adding tests
- `chore:` — Maintenance tasks

### Branch Naming

```
feature/diff-viewer
bugfix/link-data-loss
docs/readme-update
refactor/manager-cleanup
```

## 🔧 Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Write code
- Add tests if applicable
- Update documentation

### 3. Test Your Changes

```bash
# Build Swift app
cd SwiftApp && swift build

# Test CLI
npm link
dotstash add ~/.zshrc
dotstash list
dotstash link .zshrc
dotstash status
dotstash remove .zshrc
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: Add your feature description"
```

### 5. Push & Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## 🐛 Reporting Bugs

1. Check existing issues first
2. Use the bug report template
3. Include:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details
   - Console logs

## ✨ Suggesting Features

1. Check existing issues and discussions
2. Use the feature request template
3. Describe:
   - Use case
   - Proposed solution
   - Alternatives considered

## 📋 Pull Request Checklist

Before submitting your PR, ensure:

- [ ] Code follows project style guidelines
- [ ] Tests pass (if applicable)
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] PR description explains changes

## 🎯 Areas for Contribution

- 🐛 Bug fixes
- ✨ New features
- 📚 Documentation
- 🧪 Tests
- 🎨 UI/UX improvements
- ⚡ Performance optimizations
- 🌐 Localization

## 📞 Questions?

- Open a discussion on GitHub
- Check existing documentation
- Review closed issues for similar questions

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
