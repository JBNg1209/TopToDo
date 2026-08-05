#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="TopToDo"
APP_EXECUTABLE="$ROOT_DIR/dist/$APP_NAME.app/Contents/MacOS/$APP_NAME"
WORK_DIR="$(mktemp -d "$ROOT_DIR/.ui-smoke.XXXXXX")"
DATA_FILE="$WORK_DIR/todos.json"
LOG_FILE="$WORK_DIR/app.log"
APP_PID=""

cleanup() {
    if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
        kill "$APP_PID" 2>/dev/null || true
        wait "$APP_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

if [[ ! -x "$APP_EXECUTABLE" ]]; then
    echo "UI smoke check requires dist/TopToDo.app. Run make app first." >&2
    exit 1
fi

echo "Launching an isolated TopToDo instance..."
TOPTODO_PERSISTENCE_URL="$DATA_FILE" "$APP_EXECUTABLE" >"$LOG_FILE" 2>&1 &
APP_PID=$!

osascript - "$APP_NAME" <<'APPLESCRIPT'
on elementWithIdentifier(rootElement, wantedIdentifier)
    try
        if (value of attribute "AXIdentifier" of rootElement as text) is wantedIdentifier then
            return rootElement
        end if
    end try

    try
        repeat with childElement in (UI elements of rootElement)
            set foundElement to my elementWithIdentifier(childElement, wantedIdentifier)
            if foundElement is not missing value then
                return foundElement
            end if
        end repeat
    end try

    return missing value
end elementWithIdentifier

on waitForElement(rootElement, wantedIdentifier, timeoutSeconds)
    set deadline to (current date) + timeoutSeconds
    repeat
        set foundElement to my elementWithIdentifier(rootElement, wantedIdentifier)
        if foundElement is not missing value then
            return foundElement
        end if
        if (current date) > deadline then
            error "Timed out waiting for accessibility identifier: " & wantedIdentifier
        end if
        delay 0.2
    end repeat
end waitForElement

on pressElement(targetElement)
    perform action "AXPress" of targetElement
end pressElement

on run argv
    set appName to item 1 of argv
    set smokeTitle to "UI smoke task"

    tell application "System Events"
        if not (exists process appName) then
            error "TopToDo did not appear as an accessible process."
        end if

        tell process appName
            set frontmost to true
            set mainWindow to window 1
            set taskInput to my waitForElement(mainWindow, "today.newTaskInput", 15)
            set addButton to my waitForElement(mainWindow, "today.addTask", 15)
            set value of attribute "AXValue" of taskInput to smokeTitle
            my pressElement(addButton)

            set completeButton to my waitForElement(mainWindow, "today.task.0.complete", 10)
            my pressElement(completeButton)

            set moveButton to my waitForElement(mainWindow, "today.task.0.moveToPool", 10)
            my pressElement(moveButton)
        end tell
    end tell
end run
APPLESCRIPT

sleep 1

if [[ ! -f "$DATA_FILE" ]]; then
    echo "UI smoke check failed: the isolated persistence file was not written." >&2
    exit 1
fi

if ! awk '
    /"taskPoolItems" : \[/ { inPool = 1 }
    inPool && /"title" : "UI smoke task"/ { foundTitle = 1 }
    inPool && /"isCompleted" : true/ { foundCompleted = 1 }
    END { exit !(inPool && foundTitle && foundCompleted) }
' "$DATA_FILE"; then
    echo "UI smoke check failed: expected completed task was not persisted in Task Pool." >&2
    exit 1
fi

screencapture -x "$WORK_DIR/final.png" 2>/dev/null || true
echo "UI smoke check passed. Artifacts: $WORK_DIR"
