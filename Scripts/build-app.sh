#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TopToDo"
PRODUCT_NAME="TopToDo"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-dev.local.TopToDo}"
MARKETING_VERSION="${MARKETING_VERSION:-1.0.0}"
BUNDLE_VERSION="${BUNDLE_VERSION:-1}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build --product "$PRODUCT_NAME" -c "$BUILD_CONFIGURATION"

BINARY_PATH="$(swift build --product "$PRODUCT_NAME" -c "$BUILD_CONFIGURATION" --show-bin-path)/$PRODUCT_NAME"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [[ -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$MARKETING_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUNDLE_VERSION</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Junbenz Studios.&#10;All rights reserved.&#10;junbenzng@gmail.com</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign "$CODE_SIGN_IDENTITY" "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Created $APP_DIR"
echo "Signed with: $CODE_SIGN_IDENTITY"
echo "Run with: open \"$APP_DIR\""
