# Development and validation

## Prerequisites

- macOS 14 or later.
- Swift 6 Command Line Tools for building and framework-free validation.
- A complete Xcode installation is additionally required for the XCTest suite.

Before the first build, run:

```sh
make doctor
```

The doctor script reports the selected developer directory, Swift version, SDK version, formatter availability, and whether SwiftPM can parse the package. It does not alter system configuration.

## Commands

```sh
make test         # SwiftPM XCTest suite
make validate     # Framework-free core smoke check
make build        # Build the TopToDo executable
make format-check # Check Swift formatting in Sources and Tests
make architecture-check # Enforce Core/App dependency boundaries
make check        # Run all required checks
make check-clt    # Validate and build with Command Line Tools (no XCTest)
make app          # Build dist/TopToDo.app
make dmg          # Build a DMG
make ui-smoke     # Drive a local isolated UI smoke test
```

`make check` is the required baseline before handoff. It runs formatting and architecture checks, unit tests, smoke validation, a build, and `git diff --check`.

When full Xcode is temporarily unavailable, `make check-clt` is the supported reduced check. It runs formatting and architecture checks, the framework-free Core validation, a complete application build, and `git diff --check`. It does not replace the XCTest suite; run `make check` before release once a complete Xcode toolchain is available.

Formatting uses the repository's `.swift-format` configuration, so local tools and CI apply the same style rules.

## Test guidance

- Add a SwiftPM test for every behavior change in `TopToDoCore`.
- Persistence changes must cover current writes and previously supported reads.
- Keep `TopToDoValidation` as a short end-to-end Core smoke check; do not use it as the only regression suite.
- UI changes must preserve Core/App dependency rules. Run the local UI smoke check after changing its covered interaction path, and manually smoke-test other changed UI paths.

## UI smoke check

`make ui-smoke` builds an app bundle, launches it with an isolated `TOPTODO_PERSISTENCE_URL`, and uses stable accessibility identifiers to add, complete, and move a task. It then verifies the temporary persistence file. It never opens the user's normal task data.

The script requires macOS Accessibility permission for the shell or terminal running it. It is intentionally local-only and is not part of CI because hosted runners do not provide reliable GUI accessibility permission. Do not use screen coordinates, localized labels, or visible text as automation selectors; add an accessibility identifier and label whenever a key interactive control is introduced.

## Toolchain failures

If `make doctor`, `make test`, or `make build` reports that the SDK was built by a different compiler version, select a matching complete Xcode installation with `xcode-select` or repair/reinstall the command-line tools. Do not work around a mismatched toolchain by changing product source files.
