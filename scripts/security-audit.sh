#!/bin/bash

# Dotstash Security Audit Script
# Checks file permissions, configuration, and security best practices

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons
CHECK="✅"
WARN="⚠️ "
FAIL="❌"
INFO="ℹ️ "

# Counters
PASS=0
WARNINGS=0
FAILURES=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "🔒 Dotstash Security Audit"
echo "=========================="
echo ""

# ── Helper Functions ────────────────────────────────────────

pass() {
    echo -e "  ${GREEN}$CHECK${NC} $1"
    PASS=$((PASS + 1))
}

warn() {
    echo -e "  ${YELLOW}$WARN${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

fail() {
    echo -e "  ${RED}$FAIL${NC} $1"
    FAILURES=$((FAILURES + 1))
}

info() {
    echo -e "  ${CYAN}$INFO${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "$(printf '%.0s─' {1..40})"
}

# ── 1. Check Stash Directory ────────────────────────────────

section "1️⃣  Stash Directory ($HOME/.dotstash)"

STASH_DIR="$HOME/.dotstash"

if [ ! -d "$STASH_DIR" ]; then
    info "Stash directory does not exist (no dotfiles stashed yet)"
else
    # Check directory permissions
    DIR_PERMS=$(stat -f "%Lp" "$STASH_DIR" 2>/dev/null || stat -c "%a" "$STASH_DIR" 2>/dev/null)
    
    if [ "$DIR_PERMS" = "700" ]; then
        pass "Directory permissions are secure (700)"
    elif [ "$DIR_PERMS" = "755" ] || [ "$DIR_PERMS" = "775" ]; then
        warn "Directory permissions are too open ($DIR_PERMS)"
        echo "         Recommended: chmod 700 $STASH_DIR"
    else
        fail "Directory permissions are insecure ($DIR_PERMS)"
        echo "         Run: chmod 700 $STASH_DIR"
    fi
    
    # Check owner
    DIR_OWNER=$(stat -f "%Su" "$STASH_DIR" 2>/dev/null || stat -c "%U" "$STASH_DIR" 2>/dev/null)
    CURRENT_USER=$(whoami)
    
    if [ "$DIR_OWNER" = "$CURRENT_USER" ]; then
        pass "Directory owned by correct user ($CURRENT_USER)"
    else
        fail "Directory owned by wrong user ($DIR_OWNER)"
        echo "         Run: sudo chown $CURRENT_USER:$CURRENT_USER $STASH_DIR"
    fi
    
    # Check config file
    CONFIG_FILE="$STASH_DIR/dotstash.json"
    if [ -f "$CONFIG_FILE" ]; then
        CONFIG_PERMS=$(stat -f "%Lp" "$CONFIG_FILE" 2>/dev/null || stat -c "%a" "$CONFIG_FILE" 2>/dev/null)
        
        if [ "$CONFIG_PERMS" = "600" ]; then
            pass "Config file permissions are secure (600)"
        elif [ "$CONFIG_PERMS" = "644" ] || [ "$CONFIG_PERMS" = "664" ]; then
            warn "Config file permissions are too open ($CONFIG_PERMS)"
            echo "         Recommended: chmod 600 $CONFIG_FILE"
        else
            fail "Config file permissions are insecure ($CONFIG_PERMS)"
            echo "         Run: chmod 600 $CONFIG_FILE"
        fi
        
        # Check for sensitive data in config
        if grep -q "password\|secret\|token\|key" "$CONFIG_FILE" 2>/dev/null; then
            fail "Config file may contain sensitive data"
            echo "         Review $CONFIG_FILE for secrets"
        else
            pass "No sensitive data detected in config"
        fi
    else
        info "Config file does not exist yet"
    fi
    
    # Check stashed files
    FILE_COUNT=$(find "$STASH_DIR" -type f ! -name ".DS_Store" | wc -l | tr -d ' ')
    DIR_COUNT=$(find "$STASH_DIR" -type d ! -name ".DS_Store" | wc -l | tr -d ' ')
    
    info "Found $FILE_COUNT file(s) and $DIR_COUNT director(ies)"
    
    # Check for sensitive filenames
    SENSITIVE_PATTERNS=("id_rsa" "id_ed25519" "*.pem" "*.key" "credentials" "*.env" "secret")
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if find "$STASH_DIR" -name "$pattern" 2>/dev/null | grep -q .; then
            warn "Potentially sensitive file found: $pattern"
            echo "         Consider removing sensitive files from stash"
        fi
    done
fi

# ── 2. Check Home Directory Symlinks ────────────────────────

section "2️⃣  Symlinks in Home Directory"

if [ -d "$STASH_DIR" ]; then
    # Find symlinks pointing to stash
    SYMLINKS=$(find "$HOME" -maxdepth 2 -type l -exec ls -l {} \; 2>/dev/null | grep "$STASH_DIR" || true)
    
    if [ -n "$SYMLINKS" ]; then
        echo "$SYMLINKS" | while read -r line; do
            # Extract link and target from ls -l output
            LINK=$(echo "$line" | awk '{print $NF}')
            TARGET=$(echo "$line" | awk '{print $(NF-2)}')
            
            # Skip if we couldn't parse
            if [ -z "$LINK" ] || [ -z "$TARGET" ]; then
                continue
            fi
            
            # Check if target exists
            if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
                pass "Symlink OK: $LINK → $TARGET"
            else
                warn "Broken symlink: $LINK → $TARGET"
            fi
        done
    else
        info "No Dotstash symlinks found in home directory"
    fi
fi

# ── 3. Check SSH Directory ──────────────────────────────────

section "3️⃣  SSH Directory (~/.ssh)"

SSH_DIR="$HOME/.ssh"

if [ -d "$SSH_DIR" ]; then
    SSH_PERMS=$(stat -f "%Lp" "$SSH_DIR" 2>/dev/null || stat -c "%a" "$SSH_DIR" 2>/dev/null)
    
    if [ "$SSH_PERMS" = "700" ]; then
        pass "SSH directory permissions are secure (700)"
    else
        warn "SSH directory permissions should be 700 (currently $SSH_PERMS)"
        echo "         Run: chmod 700 $SSH_DIR"
    fi
    
    # Check for private keys in Dotstash
    if [ -d "$STASH_DIR" ]; then
        PRIVATE_KEYS=$(find "$STASH_DIR" -name "id_rsa" -o -name "id_ed25519" -o -name "*.pem" 2>/dev/null || true)
        
        if [ -n "$PRIVATE_KEYS" ]; then
            fail "Private keys found in Dotstash stash!"
            echo "         These should NOT be stashed:"
            echo "$PRIVATE_KEYS" | while read -r key; do
                echo "           - $key"
            done
        else
            pass "No private keys found in stash"
        fi
    fi
else
    info "SSH directory does not exist"
fi

# ── 4. Check for Sensitive Files ────────────────────────────

section "4️⃣  Sensitive Files Check"

# Common sensitive file locations
SENSITIVE_FILES=(
    "$HOME/.aws/credentials"
    "$HOME/.env"
    "$HOME/.env.local"
    "$HOME/.gnupg"
    "$HOME/.kube/config"
    "$HOME/.docker/config.json"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if [ -e "$file" ]; then
        if [ -d "$STASH_DIR" ] && find "$STASH_DIR" -name "$(basename "$file")" 2>/dev/null | grep -q .; then
            warn "Sensitive file may be stashed: $file"
        else
            pass "Sensitive file not stashed: $file"
        fi
    fi
done

# ── 5. Check System Security ────────────────────────────────

section "5️⃣  System Security"

# Check FileVault (macOS encryption)
if command -v fdesetup &> /dev/null; then
    FILEVAULT=$(fdesetup status 2>/dev/null || echo "unknown")
    if echo "$FILEVAULT" | grep -q "On"; then
        pass "FileVault is enabled (disk encryption)"
    else
        warn "FileVault is not enabled"
        echo "         Consider enabling: System Settings → Privacy & Security → FileVault"
    fi
fi

# Check Gatekeeper
if command -v spctl &> /dev/null; then
    GATEKEEPER=$(spctl --status 2>/dev/null || echo "unknown")
    if echo "$GATEKEEPER" | grep -q "enabled"; then
        pass "Gatekeeper is enabled"
    else
        warn "Gatekeeper is disabled"
    fi
fi

# Check for automatic updates
if [ -f "$HOME/Library/Preferences/com.apple.SoftwareUpdate.plist" ]; then
    AUTO_UPDATE=$(defaults read com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "unknown")
    if [ "$AUTO_UPDATE" = "1" ]; then
        pass "Automatic updates are enabled"
    else
        warn "Automatic updates may be disabled"
    fi
fi

# ── 6. Check Dotstash Installation ──────────────────────────

section "6️⃣  Dotstash Installation"

# Check CLI
if command -v dotstash &> /dev/null; then
    CLI_PATH=$(which dotstash)
    pass "CLI installed: $CLI_PATH"
    
    # Check version
    VERSION=$(dotstash --version 2>/dev/null || echo "unknown")
    info "Version: $VERSION"
else
    info "CLI not installed globally"
fi

# Check app
APP_PATH="/Applications/Dotstash.app"
if [ -d "$APP_PATH" ]; then
    pass "App installed: $APP_PATH"
    
    # Check code signature
    if codesign --verify --quiet "$APP_PATH" 2>/dev/null; then
        pass "App is code signed"
    else
        warn "App is not code signed (OK for development)"
    fi
else
    info "App not installed in /Applications"
fi

# Check build directory
if [ -d "$PROJECT_DIR/build" ]; then
    pass "Build directory exists"
else
    info "No build directory (run scripts/build.sh to create)"
fi

# ── 7. Check Network Security ───────────────────────────────

section "7️⃣  Network Security"

# Check for exposed ports
LISTENING_PORTS=$(lsof -i -P -n 2>/dev/null | grep LISTEN | grep -v "127.0.0.1" || true)

if [ -z "$LISTENING_PORTS" ]; then
    pass "No external ports exposed"
else
    warn "External ports detected:"
    echo "$LISTENING_PORTS" | head -5 | while read -r line; do
        echo "         $line"
    done
fi

# Check firewall
if command -v /usr/libexec/ApplicationFirewall/socketfilterfw &> /dev/null; then
    FIREWALL=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")
    if echo "$FIREWALL" | grep -q "enabled"; then
        pass "macOS Firewall is enabled"
    else
        warn "macOS Firewall may be disabled"
    fi
fi

# ── Summary ─────────────────────────────────────────────────

echo ""
echo "📊 Audit Summary"
echo "================"
echo ""
echo -e "  ${GREEN}$CHECK Passed:${NC}     $PASS"
echo -e "  ${YELLOW}$WARN Warnings:${NC}   $WARNINGS"
echo -e "  ${RED}$FAIL Failures:${NC}   $FAILURES"
echo ""

TOTAL=$((PASS + WARNINGS + FAILURES))

if [ $FAILURES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Excellent! No security issues found.${NC}"
elif [ $FAILURES -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Good, but there are $WARNINGS warning(s) to address.${NC}"
else
    echo -e "${RED}🚨 There are $FAILURES failure(s) that should be fixed immediately.${NC}"
fi

echo ""
echo "💡 Recommendations:"
echo ""
echo "   1. Fix any failures before using Dotstash with sensitive files"
echo "   2. Review warnings for potential security improvements"
echo "   3. Run this audit regularly: ./scripts/security-audit.sh"
echo "   4. Never stash files containing passwords, keys, or tokens"
echo ""

# Return exit code
if [ $FAILURES -gt 0 ]; then
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    exit 0
else
    exit 0
fi
