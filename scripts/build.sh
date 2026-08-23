#!/bin/bash

# Dotstash Build Script
# Builds the SwiftUI app, creates .app bundle, and packages as DMG

set -e

# Configuration
APP_NAME="Dotstash"
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SWIFT_DIR="$PROJECT_DIR/SwiftApp"
BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"

echo "🔨 Building Dotstash v$VERSION"
echo "================================"

# Clean previous builds
echo "📁 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Build release binary
echo "⚙️  Building release binary..."
cd "$SWIFT_DIR"
pwd
swift build -c release 2>&1 | tail -5

# Copy binary to bundle
echo "📦 Creating app bundle..."
cp "$SWIFT_DIR/.build/arm64-apple-macosx/release/DotstashApp" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

# Copy Sparkle framework into app bundle
echo "📦 Copying Sparkle framework..."
mkdir -p "$BUNDLE_DIR/Contents/Frameworks"
cp -R "$SWIFT_DIR/.build/arm64-apple-macosx/release/Sparkle.framework" "$BUNDLE_DIR/Contents/Frameworks/"

# Update rpath for Sparkle
codesign --remove-signature "$BUNDLE_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../Frameworks" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$BUNDLE_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.perigrino.dotstash</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Perigrino. All rights reserved.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.home-relative-path.read-write</key>
    <array>
        <string>/</string>
    </array>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/YOUR_USERNAME/dotstash/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>YOUR_SPARKLE_PUBLIC_KEY_HERE</string>
</dict>
</plist>
PLIST

# Generate app icon
echo "🎨 Generating app icon..."
cat > /tmp/create_icon.swift << 'SWIFT'
import Cocoa
import Foundation

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

// Draw rounded rectangle background
let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 224, yRadius: 224)
let gradient = NSGradient(starting: NSColor(red: 0.4, green: 0.49, blue: 0.92, alpha: 1.0),
                         ending: NSColor(red: 0.46, green: 0.29, blue: 0.64, alpha: 1.0))
gradient?.draw(in: path, angle: 135)

// Draw tray icon
NSColor.white.setStroke()
NSBezierPath.defaultLineWidth = 60

let topPath = NSBezierPath()
topPath.move(to: NSPoint(x: 256, y: 512))
topPath.line(to: NSPoint(x: 768, y: 512))
topPath.stroke()

let leftPath = NSBezierPath()
leftPath.move(to: NSPoint(x: 256, y: 512))
leftPath.line(to: NSPoint(x: 256, y: 384))
leftPath.stroke()

let rightPath = NSBezierPath()
rightPath.move(to: NSPoint(x: 768, y: 512))
rightPath.line(to: NSPoint(x: 768, y: 384))
rightPath.stroke()

let bottomPath = NSBezierPath()
bottomPath.move(to: NSPoint(x: 256, y: 512))
bottomPath.line(to: NSPoint(x: 256, y: 640))
bottomPath.line(to: NSPoint(x: 768, y: 640))
bottomPath.line(to: NSPoint(x: 768, y: 512))
bottomPath.stroke()

image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "/tmp/dotstash_icon.png")
    try! pngData.write(to: url)
    print("Icon created")
}
SWIFT

swift /tmp/create_icon.swift

# Create iconset
mkdir -p /tmp/Dotstash.iconset
for size in 16 32 64 128 256 512; do
    sips -z $size $size /tmp/dotstash_icon.png --out "/tmp/Dotstash.iconset/icon_${size}x${size}.png" > /dev/null 2>&1
    sips -z $((size*2)) $((size*2)) /tmp/dotstash_icon.png --out "/tmp/Dotstash.iconset/icon_${size}x${size}@2x.png" > /dev/null 2>&1
done

iconutil -c icns /tmp/Dotstash.iconset -o "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"

# Code sign (optional - for distribution)
echo "🔒 Code signing..."
codesign --force --deep --sign - "$BUNDLE_DIR" || echo "⚠️  Code signing skipped (not required for local use)"

# Create DMG
echo "💿 Creating DMG..."
TEMP_DIR="$BUILD_DIR/dmg_temp"
mkdir -p "$TEMP_DIR"
cp -R "$BUNDLE_DIR" "$TEMP_DIR/"
ln -s /Applications "$TEMP_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$BUILD_DIR/$DMG_NAME"

rm -rf "$TEMP_DIR"

# Get DMG size
DMG_SIZE=$(du -h "$BUILD_DIR/$DMG_NAME" | cut -f1)

echo ""
echo "✅ Build complete!"
echo "   App: $BUNDLE_DIR"
echo "   DMG: $BUILD_DIR/$DMG_NAME ($DMG_SIZE)"
echo ""

# Calculate checksums
echo "📊 Checksums:"
shasum -a 256 "$BUILD_DIR/$DMG_NAME"
