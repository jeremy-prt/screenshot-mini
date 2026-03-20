#!/bin/bash
set -euo pipefail

APP_NAME="Screenshot Mini"
BUNDLE_ID="com.local.ScreenshotMini"
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building..."
swift build -c release 2>&1

echo "Creating app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp .build/release/ScreenshotMini "$APP_BUNDLE/Contents/MacOS/ScreenshotMini"

# Copy icons
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
if [ -f "Resources/menubar-icon.png" ]; then
    cp Resources/menubar-icon.png "$APP_BUNDLE/Contents/Resources/menubar-icon.png"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.local.ScreenshotMini</string>
    <key>CFBundleName</key>
    <string>Screenshot Mini</string>
    <key>CFBundleDisplayName</key>
    <string>Screenshot Mini</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ScreenshotMini</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
</dict>
</plist>
PLIST

# Sign with stable dev certificate (preserves TCC permissions across rebuilds)
codesign --force --deep -s "ScreenshotMini Dev" "$APP_BUNDLE"

INSTALLED="/Applications/$APP_NAME.app"
if [ -d "$INSTALLED" ]; then
    echo "Updating installed app..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    # Copy and re-sign with same stable certificate to preserve TCC permissions
    cp "$APP_BUNDLE/Contents/MacOS/ScreenshotMini" "$INSTALLED/Contents/MacOS/ScreenshotMini"
    cp "$APP_BUNDLE/Contents/Info.plist" "$INSTALLED/Contents/Info.plist"
    codesign --force --deep -s "ScreenshotMini Dev" "$INSTALLED"
    xattr -cr "$INSTALLED" 2>/dev/null || true
    echo "Updated. Relaunching..."
    open "$INSTALLED"
else
    echo ""
    echo "First install: copying to /Applications..."
    cp -R "$APP_BUNDLE" /Applications/
    xattr -cr "$INSTALLED" 2>/dev/null || true
    echo "Installed. Launching..."
    open "$INSTALLED"
fi
