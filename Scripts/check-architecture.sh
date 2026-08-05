#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

report_failure() {
    echo "Architecture check failed: $1" >&2
    echo "Remediation: $2" >&2
    failures=1
}

if grep -r -n -E '^import (SwiftUI|AppKit)$' Sources/TopToDoCore >/dev/null; then
    report_failure \
        "TopToDoCore must not import SwiftUI or AppKit." \
        "Move presentation code to Sources/TopToDoApp; keep Core focused on domain state and persistence."
fi

if grep -r -n -E 'FileManager|Data\(contentsOf:|JSON(Encoder|Decoder)|todos\.json' Sources/TopToDoApp >/dev/null; then
    report_failure \
        "TopToDoApp must not directly read or write todo persistence data." \
        "Route task state and persistence through TodoStore in Sources/TopToDoCore."
fi

if grep -r -n -E '^import TopToDoApp$' Tests >/dev/null; then
    report_failure \
        "Core regression tests must not depend on TopToDoApp." \
        "Keep Core tests in Tests/TopToDoCoreTests and test presentation separately."
fi

if [[ ! -d Sources/TopToDoCore || ! -d Sources/TopToDoApp || ! -d Tests/TopToDoCoreTests ]]; then
    report_failure \
        "Expected source or test directories are missing." \
        "Restore the TopToDoCore, TopToDoApp, and TopToDoCoreTests directory structure."
fi

if [[ "$failures" -ne 0 ]]; then
    exit 1
fi

echo "Architecture check passed"
