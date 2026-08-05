# Changelog

All notable user-facing or maintenance-relevant changes are recorded here.

## 1.3.0

- Added gray and blue task highlights alongside the existing red highlight.
- Added a color-preserving highlight picker with visible red, gray, and blue flags.
- Added a visible last-modified timestamp beneath every task title.
- Increased the fixed app window width from 600 to 750 points.
- Preserved compatibility with legacy boolean highlight data and tasks without last-modified metadata.
- Added repeatable architecture, persistence, validation, CI, and Command Line Tools checks.

## 1.2.0

- Added task highlighting, move-to-top, move-up, and move-down actions.
- Added per-task single-shot reminders with app-runtime alert dialogs and persistence.
- Replaced the reminder calendar with compact year, month, day, hour, and five-minute selectors.
- Reworked row actions so frequent controls remain visible and lower-frequency controls live in the more menu.
- Aligned Today behavior with persistent Top5 product rules and removed obsolete `iDo` migration handling from the default persistence path.
- Added project documentation and validation for persistence, task movement, reminder metadata, and the removal of date-reset metadata.

## 1.1.0

- Published the DMG download and documented the Today Top5 and Task Pool workflow.
- Documented trilingual UI, font-size controls, inline editing, task movement, and JSON persistence.

## Earlier development

- The app began under the internal `iDo` name and was renamed to TopToDo before public release.
