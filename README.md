# TopToDo

TopToDo is a small macOS Todo app written in Swift and SwiftUI. It supports adding tasks, listing tasks, marking tasks complete, deleting tasks, and saving todos between launches.

The app is built around the "less is more" philosophy: a persistent 5-slot Today Top5 for the things that matter most, plus a longer-term Task Pool of up to 30 tasks. Neither list auto-resets — what you add stays until you complete, move, or delete it.

## Download

Pre-built DMG is available on the [Releases page](../../releases).

| File | Size | SHA256 |
| --- | --- | --- |
| [TopToDo-1.2.0.dmg](../../releases/download/v1.2.0/TopToDo-1.2.0.dmg) | 1.06 MB | `051a9f6a96dae150c5c1a4e40f2491318eb6764c584d66809234ac16bb246449` |

Verify the download:

```sh
shasum -a 256 TopToDo-1.2.0.dmg
```

After mounting the DMG, drag `TopToDo.app` into the Applications folder. The build is currently signed with an ad-hoc signature, so on first launch macOS will ask you to confirm in **System Settings → Privacy & Security**.

## Requirements

- macOS 14 or later
- Swift 6.0 or later

## Run

```sh
cd TopToDo
make app
open dist/TopToDo.app
```

`swift run TopToDo` can show the SwiftUI window, but Terminal may keep keyboard focus because it is not launching a full macOS app bundle. Use `make app` and `open dist/TopToDo.app` for normal text input behavior.

`make app` signs the bundle with an ad-hoc signature by default. For a Developer ID signed build, pass your signing identity and release metadata:

```sh
BUILD_CONFIGURATION=release \
BUNDLE_IDENTIFIER=com.example.TopToDo \
MARKETING_VERSION=1.2.0 \
BUNDLE_VERSION=1 \
CODE_SIGN_IDENTITY="Developer ID Application: Example Team (TEAMID)" \
make app
```

## Validate

```sh
cd TopToDo
swift run TopToDoValidation
swift build --product TopToDo
```

## Features

- **Today Top5** — a persistent 5-slot list. Tasks you add stay until you complete, move, or delete them; no midnight auto-reset.
- **Task Pool** — up to 30 long-term tasks. One click moves a task between Top5 and the Pool.
- **Inline editing** — click any task to edit; commit on focus loss or Return.
- **Empty-title guard** — saving a blank title is rejected with an alert, so the only way to remove a task is the trash button.
- **Trilingual UI** — English / 简体中文 / 繁體中文.
- **Adjustable font size** — Small / Medium / Large / Extra Large, applies to the whole app except the screen title.
- **Adjustable language** — switchable from the top-right of the window, no relaunch needed.
- **Persisted at** `~/Library/Application Support/TopToDo/todos.json`.

## Project Structure

```text
TopToDo/
├── Makefile
├── Package.swift
├── Scripts/
│   └── build-app.sh # Builds dist/TopToDo.app
├── Sources/
│   ├── TopToDoApp/        # SwiftUI macOS app
│   ├── TopToDoCore/       # Todo model and store
│   └── TopToDoValidation/ # Framework-free validation executable
```
