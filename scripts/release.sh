#!/bin/bash

# Dotstash Release Script
# Creates a GitHub release and uploads the DMG

set -e

# Configuration
VERSION="${1:-2.0.0}"
REPO="YOUR_USERNAME/dotstash"
BUILD_DIR="$(dirname "$0")/../build"
DMG_NAME="Dotstash-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo "   Install it with: brew install gh"
    echo "   Then authenticate: gh auth login"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not authenticated.${NC}"
    echo "   Run: gh auth login"
    exit 1
fi

if [ ! -f "$DMG_PATH" ]; then
    echo -e "${YELLOW}⚠️  DMG not found. Building first...${NC}"
    bash "$(dirname "$0")/build.sh"
fi

if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}❌ DMG build failed.${NC}"
    exit 1
fi

echo ""
echo "🚀 Creating release v$VERSION"
echo "================================"

# Get the checksum
CHECKSUM=$(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)

# Create release notes
cat > /tmp/release_notes.md << NOTES
## 🚀 What's New in v$VERSION

### ✨ Features
- 📊 Native SwiftUI dashboard with dotfile cards
- 🔍 Diff viewer with unified and side-by-side views
- 🎨 Syntax highlighting for config files
- 📁 Drag-and-drop support
- 🔄 Live file watching with auto-refresh
- 📤 Export/import for transferring between machines
- 🛡️ Safety features: drift detection and diff-and-refuse
- 🌐 Menu bar integration with badge count
- ⚙️ Auto-update support via Sparkle

### 🛡️ Safety Improvements
- **Drift Detection**: Prevents overwriting modified files
- **Diff-and-Refuse**: Shows options when conflicts are detected
- **Namespaced Paths**: Avoids basename collisions
- **Content Hashing**: SHA-256 tracks file state

### 📦 Installation
1. Download \`$DMG_NAME\` below
2. Open the DMG
3. Drag Dotstash to Applications
4. Launch from Applications

> ⚠️ First launch: Right-click → Open (to bypass Gatekeeper)

### 📋 Checksums
\`\`\`
$CHECKSUM  $DMG_NAME
\`\`\`

### 🙏 Thanks
Thanks to everyone who contributed feedback and bug reports!
NOTES

# Create the release
echo ""
echo "📦 Uploading to GitHub..."

gh release create "v$VERSION" \
    "$DMG_PATH" \
    --title "Dotstash v$VERSION" \
    --notes-file /tmp/release_notes.md \
    --repo "$REPO"

echo ""
echo -e "${GREEN}✅ Release v$VERSION created successfully!${NC}"
echo ""
echo "🔗 View at: https://github.com/$REPO/releases/tag/v$VERSION"
echo ""

# Clean up
rm -f /tmp/release_notes.md
