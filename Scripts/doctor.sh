#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVELOPER_DIR="$(xcode-select -p)"

echo "Developer directory: $DEVELOPER_DIR"
echo "Swift:"
xcrun swift --version
echo "macOS SDK: $(xcrun --show-sdk-version)"
echo "swift-format: $(xcrun --find swift-format 2>/dev/null || echo 'not found')"

if [[ "$DEVELOPER_DIR" == "/Library/Developer/CommandLineTools" ]]; then
    echo "Full Xcode is required for the XCTest suite; Command Line Tools alone does not provide XCTest."
    echo "Install Xcode, then select it with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

echo "Checking SwiftPM manifest..."
cd "$ROOT_DIR"
swift package describe --type json >/dev/null
echo "SwiftPM manifest: OK"
