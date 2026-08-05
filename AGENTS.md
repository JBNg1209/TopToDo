# TopToDo agent guide

TopToDo is a focused native macOS todo app. Keep changes small, preserve product decisions, and make every behavior change verifiable.

## Start here

1. Read [the documentation index](docs/README.md).
2. Read [product rules](docs/product.md) before changing behavior.
3. Read [architecture](docs/architecture.md) before changing module boundaries.
4. Read [development](docs/development.md) before running or validating the app.
5. Consult [roadmap](docs/roadmap.md) before proposing new scope.

## Non-negotiable rules

- Today has exactly five persistent slots and never resets by date.
- Task Pool contains at most 30 tasks.
- Completing a task clears its reminder.
- Moving a task preserves its identity and metadata, while trimming its title.
- Blank titles are rejected during editing; deletion is explicit.
- Do not add accounts, cloud sync, recurring tasks, projects, or additional platforms unless the request explicitly changes scope.

## Required validation

Run `make check` for code changes. Run `make doctor` first when the local Swift toolchain has not been validated or when a Swift command fails before building the package.

For behavior changes, add or update a SwiftPM test. For persistence changes, cover old data formats and the format written after the change. For UI changes, preserve the Core/App dependency direction and update the product documentation when the user-visible behavior changes.

Interactive controls in key workflows require a stable, non-localized accessibility identifier plus an accessibility label. Update `Scripts/ui-smoke.sh` when changing the smoke-tested add, complete, or move flow. Do not use screen coordinates or visible text as UI automation selectors.

## Documentation updates

- Product behavior or constraints: update `docs/product.md`.
- Module responsibilities or dependency directions: update `docs/architecture.md`.
- Build, test, or tooling changes: update `docs/development.md`.
- Release-facing changes: update `docs/changelog.md` and, when relevant, `docs/release.md`.
