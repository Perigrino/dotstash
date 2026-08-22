#!/bin/bash

# Dotstash Version Bump Script
# Updates all version numbers across the project

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Current version (read from package.json)
CURRENT_VERSION=$(grep -o '"version": "[^"]*"' "$PROJECT_DIR/package.json" | cut -d'"' -f4)

# Parse arguments
BUMP_TYPE=""
NEW_VERSION=""

usage() {
    echo ""
    echo "📦 Dotstash Version Bumper"
    echo "========================"
    echo ""
    echo "Usage: $0 <bump-type> | --version <version>"
    echo ""
    echo "Bump Types:"
    echo "  major    - X.0.0 (breaking changes)"
    echo "  minor    - x.Y.0 (new features)"
    echo "  patch    - x.y.Z (bug fixes)"
    echo "  premajor - X.0.0-beta.1"
    echo "  preminor - x.Y.0-beta.1"
    echo "  prepatch - x.y.Z-beta.1"
    echo "  prerelease - x.y.Z-beta.N"
    echo ""
    echo "Examples:"
    echo "  $0 minor                    # 2.0.0 → 2.1.0"
    echo "  $0 patch                    # 2.0.0 → 2.0.1"
    echo "  $0 major                    # 2.0.0 → 3.0.0"
    echo "  $0 --version 2.5.0          # Set to 2.5.0"
    echo "  $0 prerelease               # 2.0.0 → 2.0.1-beta.1"
    echo ""
    echo "Current version: $CURRENT_VERSION"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        major|minor|patch|premajor|preminor|prepatch|prerelease)
            BUMP_TYPE="$1"
            shift
            ;;
        --version)
            NEW_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Validate input
if [ -z "$BUMP_TYPE" ] && [ -z "$NEW_VERSION" ]; then
    echo -e "${RED}❌ Error: Please specify a bump type or version${NC}"
    usage
fi

# Calculate new version if bump type specified
if [ -n "$BUMP_TYPE" ]; then
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    
    # Handle pre-release versions
    PRE_RELEASE=""
    if [[ "$PATCH" == *"-"* ]]; then
        PATCH=$(echo "$PATCH" | cut -d'-' -f1)
        PRE_RELEASE=$(echo "$CURRENT_VERSION" | cut -d'-' -f2-)
    fi
    
    case $BUMP_TYPE in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            PRE_RELEASE=""
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            PRE_RELEASE=""
            ;;
        patch)
            if [ -n "$PRE_RELEASE" ]; then
                PRE_RELEASE=""
            else
                PATCH=$((PATCH + 1))
            fi
            ;;
        premajor)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            PRE_RELEASE="beta.1"
            ;;
        preminor)
            MINOR=$((MINOR + 1))
            PATCH=0
            PRE_RELEASE="beta.1"
            ;;
        prepatch)
            PATCH=$((PATCH + 1))
            PRE_RELEASE="beta.1"
            ;;
        prerelease)
            if [ -z "$PRE_RELEASE" ]; then
                PATCH=$((PATCH + 1))
                PRE_RELEASE="beta.1"
            else
                # Increment pre-release number
                PRE_NUM=$(echo "$PRE_RELEASE" | grep -o '[0-9]*$')
                PRE_NAME=$(echo "$PRE_RELEASE" | sed 's/[0-9]*$//')
                NEW_PRE_NUM=$((PRE_NUM + 1))
                PRE_RELEASE="${PRE_NAME}${NEW_PRE_NUM}"
            fi
            ;;
    esac
    
    if [ -n "$PRE_RELEASE" ]; then
        NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}-${PRE_RELEASE}"
    else
        NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
    fi
fi

# Validate version format
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo -e "${RED}❌ Invalid version format: $NEW_VERSION${NC}"
    echo "   Expected: X.Y.Z or X.Y.Z-prerelease"
    exit 1
fi

echo ""
echo "📦 Dotstash Version Bumper"
echo "========================"
echo ""
echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "New version:     ${GREEN}$NEW_VERSION${NC}"
echo ""

# Confirm
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  Cancelled${NC}"
    exit 0
fi

echo ""
echo "📝 Updating version numbers..."
echo ""

# Function to update file
update_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    
    if [ -f "$file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|$pattern|$replacement|g" "$file"
        else
            sed -i "s|$pattern|$replacement|g" "$file"
        fi
        echo -e "  ${GREEN}✓${NC} Updated $file"
    else
        echo -e "  ${YELLOW}⚠${NC} File not found: $file"
    fi
}

# 1. Update package.json
echo "1️⃣  Updating package.json..."
update_file "$PROJECT_DIR/package.json" \
    "\"version\": \"$CURRENT_VERSION\"" \
    "\"version\": \"$NEW_VERSION\""

# 2. Update build.sh
echo "2️⃣  Updating build.sh..."
update_file "$PROJECT_DIR/scripts/build.sh" \
    "VERSION=\"$CURRENT_VERSION\"" \
    "VERSION=\"$NEW_VERSION\""

# 3. Update SwiftApp Info.plist (if exists)
echo "3️⃣  Updating SwiftApp Info.plist..."
update_file "$PROJECT_DIR/build/Dotstash.app/Contents/Info.plist" \
    "<string>$CURRENT_VERSION</string>" \
    "<string>$NEW_VERSION</string>" 2>/dev/null || true

# 4. Update UpdaterController.swift
echo "4️⃣  Updating UpdaterController.swift..."
update_file "$PROJECT_DIR/SwiftApp/Sources/DotstashApp/Models/UpdaterController.swift" \
    "\"version\": \"$CURRENT_VERSION\"" \
    "\"version\": \"$NEW_VERSION\"" 2>/dev/null || true

# 5. Update README.md badges
echo "5️⃣  Updating README.md..."
update_file "$PROJECT_DIR/README.md" \
    "v$CURRENT_VERSION" \
    "v$NEW_VERSION" 2>/dev/null || true

# 6. Update appcast.xml
echo "6️⃣  Updating appcast.xml..."
update_file "$PROJECT_DIR/SwiftApp/appcast.xml" \
    "<string>$CURRENT_VERSION</string>" \
    "<string>$NEW_VERSION</string>" 2>/dev/null || true
update_file "$PROJECT_DIR/SwiftApp/appcast.xml" \
    "sparkle:shortVersionString>$CURRENT_VERSION<" \
    "sparkle:shortVersionString>$NEW_VERSION<" 2>/dev/null || true

# 7. Create git tag (optional)
echo ""
read -p "Create git tag v$NEW_VERSION? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"
    git add -A
    git commit -m "chore: bump version to v$NEW_VERSION"
    git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
    echo -e "  ${GREEN}✓${NC} Created tag v$NEW_VERSION"
fi

echo ""
echo "✅ Version bumped to $NEW_VERSION"
echo ""
echo "📋 Next steps:"
echo "   1. Review changes: git diff"
echo "   2. Push changes:   git push && git push --tags"
echo "   3. Build DMG:      ./scripts/build.sh"
echo "   4. Create release: ./scripts/release.sh $NEW_VERSION"
echo ""
