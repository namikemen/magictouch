#!/bin/zsh
set -e

# Version can be passed as first argument, e.g. ./package_app.sh 1.0.0
RAW_VERSION="${1:-1.0.0}"
# Strip leading 'v' if present
VERSION="${RAW_VERSION#v}"

SDK_PATH=$(xcrun --show-sdk-path)
DIST_DIR=".build/dist"
OBJ_DIR=".build/obj"
BIN_DIR=".build/bin"
CACHE_DIR="$PWD/.cache"
DMG_STAGE=".build/dmg_stage"

echo "========================================================"
echo " Packaging MagicTouch macOS (Version: $VERSION)"
echo "========================================================"

mkdir -p "$DIST_DIR" "$OBJ_DIR" "$BIN_DIR" "$CACHE_DIR/clang" "$CACHE_DIR/module" "$CACHE_DIR/sdk"
rm -rf "$DIST_DIR/MagicTouch.app" "$DIST_DIR/MagicTouch.dmg" "$DIST_DIR/MagicTouch.app.tar.gz" "$DIST_DIR/MagicTouch-macOS.zip" "$DMG_STAGE"

SWIFT_SOURCES=(
  Sources/MagicTouch/Models/*.swift
  Sources/MagicTouch/Engine/*.swift
  Sources/MagicTouch/Store/*.swift
  Sources/MagicTouch/Views/*.swift
  Sources/MagicTouch/main.swift
)

# 1. Compile arm64 (Apple Silicon)
echo "==> [1/6] Compiling for arm64 (Apple Silicon)..."
clang -target arm64-apple-macos13.0 -c Sources/MultitouchBridge/MultitouchBridge.m \
  -isysroot "$SDK_PATH" \
  -I Sources/MultitouchBridge/include \
  -F /System/Library/PrivateFrameworks \
  -fmodules-cache-path="$CACHE_DIR/clang" \
  -o "$OBJ_DIR/MultitouchBridge_arm64.o"

swiftc -target arm64-apple-macos13.0 \
  -parse-as-library \
  -sdk "$SDK_PATH" \
  -module-cache-path "$CACHE_DIR/module" \
  -Xcc -fmodules-cache-path="$CACHE_DIR/clang" \
  -F /System/Library/PrivateFrameworks \
  -framework MultitouchSupport \
  -framework AppKit \
  -framework SwiftUI \
  -framework CoreGraphics \
  -framework IOKit \
  -I Sources/MultitouchBridge/include \
  "$OBJ_DIR/MultitouchBridge_arm64.o" \
  "${SWIFT_SOURCES[@]}" \
  -o "$BIN_DIR/MagicTouch_arm64"

# 2. Compile x86_64 (Intel)
echo "==> [2/6] Compiling for x86_64 (Intel)..."
clang -target x86_64-apple-macos13.0 -c Sources/MultitouchBridge/MultitouchBridge.m \
  -isysroot "$SDK_PATH" \
  -I Sources/MultitouchBridge/include \
  -F /System/Library/PrivateFrameworks \
  -fmodules-cache-path="$CACHE_DIR/clang" \
  -o "$OBJ_DIR/MultitouchBridge_x86_64.o"

swiftc -target x86_64-apple-macos13.0 \
  -parse-as-library \
  -sdk "$SDK_PATH" \
  -module-cache-path "$CACHE_DIR/module" \
  -Xcc -fmodules-cache-path="$CACHE_DIR/clang" \
  -F /System/Library/PrivateFrameworks \
  -framework MultitouchSupport \
  -framework AppKit \
  -framework SwiftUI \
  -framework CoreGraphics \
  -framework IOKit \
  -I Sources/MultitouchBridge/include \
  "$OBJ_DIR/MultitouchBridge_x86_64.o" \
  "${SWIFT_SOURCES[@]}" \
  -o "$BIN_DIR/MagicTouch_x86_64"

# 3. Assemble Universal Binary with lipo
echo "==> [3/6] Merging into Universal Binary..."
APP_BUNDLE="$DIST_DIR/MagicTouch.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

lipo -create "$BIN_DIR/MagicTouch_arm64" "$BIN_DIR/MagicTouch_x86_64" -output "$APP_BUNDLE/Contents/MacOS/MagicTouch"
chmod +x "$APP_BUNDLE/Contents/MacOS/MagicTouch"

# Copy App Icon & Branding Resources
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
elif [ -f "logo.png" ]; then
    echo "==> Generating AppIcon.icns from logo.png..."
    mkdir -p .build/AppIcon.iconset
    sips -z 16 16     logo.png --out .build/AppIcon.iconset/icon_16x16.png >/dev/null 2>&1
    sips -z 32 32     logo.png --out .build/AppIcon.iconset/icon_16x16@2x.png >/dev/null 2>&1
    sips -z 32 32     logo.png --out .build/AppIcon.iconset/icon_32x32.png >/dev/null 2>&1
    sips -z 64 64     logo.png --out .build/AppIcon.iconset/icon_32x32@2x.png >/dev/null 2>&1
    sips -z 128 128   logo.png --out .build/AppIcon.iconset/icon_128x128.png >/dev/null 2>&1
    sips -z 256 256   logo.png --out .build/AppIcon.iconset/icon_128x128@2x.png >/dev/null 2>&1
    sips -z 256 256   logo.png --out .build/AppIcon.iconset/icon_256x256.png >/dev/null 2>&1
    sips -z 512 512   logo.png --out .build/AppIcon.iconset/icon_256x256@2x.png >/dev/null 2>&1
    sips -z 512 512   logo.png --out .build/AppIcon.iconset/icon_512x512.png >/dev/null 2>&1
    sips -z 1024 1024 logo.png --out .build/AppIcon.iconset/icon_512x512@2x.png >/dev/null 2>&1
    iconutil -c icns .build/AppIcon.iconset -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf .build/AppIcon.iconset
fi

if [ -f "logo.png" ]; then
    cp "logo.png" "$APP_BUNDLE/Contents/Resources/logo.png"
fi

# Generate Info.plist
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MagicTouch</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.namikemen.magictouch</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MagicTouch</string>
    <key>CFBundleDisplayName</key>
    <string>MagicTouch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>MagicTouch uses Apple Events to trigger custom scripts and actions.</string>
    <key>NSInputMonitoringUsageDescription</key>
    <string>MagicTouch uses Input Monitoring to read raw multitouch contact points from your Magic Mouse.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>MagicTouch uses Accessibility to simulate mouse clicks and keyboard shortcuts.</string>
</dict>
</plist>
EOF

echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Code sign the app bundle (ad-hoc) with bundle identifier matching Info.plist
echo "==> Signing app bundle with identifier com.namikemen.magictouch..."
codesign --force --deep --sign - --identifier "com.namikemen.magictouch" "$APP_BUNDLE"

# 4. Create DMG Installer (with graceful fallback if sandboxed)
echo "==> [4/6] Creating DMG Installer..."
mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

if hdiutil create -volname "MagicTouch" \
  -srcfolder "$DMG_STAGE" \
  -ov -format UDZO \
  "$DIST_DIR/MagicTouch.dmg" 2>/dev/null; then
    echo "    DMG created successfully."
else
    echo "    Notice: hdiutil not permitted in local sandboxed environment. Will be generated in CI runner."
fi
rm -rf "$DMG_STAGE"

# 5. Create .app.tar.gz and .zip Archives
echo "==> [5/6] Creating MagicTouch.app.tar.gz and MagicTouch-macOS.zip archives..."
tar -czf "$DIST_DIR/MagicTouch.app.tar.gz" -C "$DIST_DIR" MagicTouch.app
(cd "$DIST_DIR" && zip -r -y -q "MagicTouch-macOS.zip" MagicTouch.app)

# 6. Generate Checksums
echo "==> [6/6] Generating SHA256 checksums..."
cd "$DIST_DIR"
shasum -a 256 *.* > checksums.txt 2>/dev/null || true
cd - > /dev/null

echo "========================================================"
echo " Build & Packaging Complete!"
echo " Universal Binary architectures:"
lipo -info "$APP_BUNDLE/Contents/MacOS/MagicTouch"
echo ""
echo " Assets created in $DIST_DIR:"
ls -lh "$DIST_DIR"
echo "========================================================"
