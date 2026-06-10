# TopToDo

TopToDo is a small macOS Todo app written in Swift and SwiftUI. It supports adding tasks, listing tasks, marking tasks complete, deleting tasks, and saving todos between launches.

## Download

Pre-built DMG is available on the [Releases page](../../releases).

| File | Size | SHA256 |
| --- | --- | --- |
| [TopToDo-1.0.0.dmg](../../releases/download/v1.0.0/TopToDo-1.0.0.dmg) | 922 KB | `65e42b8d605dcde6af496929a9f070662d9309c60cd4f4ace0c044ac5bbff210` |

Verify the download:

```sh
shasum -a 256 TopToDo-1.0.0.dmg
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
MARKETING_VERSION=1.0.0 \
BUNDLE_VERSION=1 \
CODE_SIGN_IDENTITY="Developer ID Application: Example Team (TEAMID)" \
make app
```

## Validate

```sh
cd TopToDo
swift run TopToDoValidation
swift build
```

## Features

- Add a task with the text field or Return key.
- View all tasks in a native macOS list.
- Click a task row to mark it complete or open again.
- Delete tasks from the list.
- Persist tasks at `~/Library/Application Support/TopToDo/todos.json`.

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
