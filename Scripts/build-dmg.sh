#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TopToDo"
MARKETING_VERSION="${MARKETING_VERSION:-1.0.0}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/$APP_NAME-$MARKETING_VERSION.dmg"

cd "$ROOT_DIR"

MARKETING_VERSION="$MARKETING_VERSION" \
BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
    "$ROOT_DIR/Scripts/build-app.sh"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"
rm -rf "$DMG_ROOT"

echo "Created $DMG_PATH"
