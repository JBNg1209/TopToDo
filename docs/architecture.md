# Architecture

TopToDo uses Swift Package Manager and is intentionally split into a small domain layer and a native UI layer.

| Module | Responsibility | May depend on |
| --- | --- | --- |
| `TopToDoCore` | Todo model, state changes, limits, JSON persistence | Foundation, Combine |
| `TopToDoApp` | SwiftUI/AppKit presentation, localization, reminders, app lifecycle | `TopToDoCore`, SwiftUI, AppKit/Combine |
| `TopToDoValidation` | Framework-free smoke check | `TopToDoCore` |
| `TopToDoCoreTests` | XCTest regression suite | `TopToDoCore`, XCTest |

## Dependency rules

- `TopToDoCore` must not import SwiftUI or AppKit.
- `TopToDoApp` owns presentation and runtime reminder scheduling; Core owns persisted task state.
- UI code must not read or write the persistence file directly.
- Tests and validation may exercise Core but must not become dependencies of the shipping app.

`Scripts/check-architecture.sh` enforces these rules in `make check`. Its diagnostics are deliberately narrow and include the required remediation; expand the script only when a new structural rule has demonstrated value.

`TodoListView.swift` is the primary screen. Keep new UI behavior in focused subviews or supporting types when possible, so task-row behavior remains locally understandable.
