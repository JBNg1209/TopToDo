# Product rules

TopToDo is a deliberately small native macOS todo app built around a persistent Today Top5 and a longer-term Task Pool.

## Non-negotiable behavior

- Today always has exactly five slots. It persists across launches and never resets at midnight or based on a date key.
- Completed Today tasks continue to occupy a slot until the user clears, moves, or edits them.
- Task Pool contains no more than 30 tasks.
- A task may be completed, highlighted in red, gray, or blue, and assigned one single-shot reminder datetime.
- Task rows show the title and a local last-modified timestamp with second precision. Creation and title edits refresh this timestamp; completion, highlighting, reminders, reordering, and list moves do not.
- Completing a task clears its reminder.
- Moving between Today and Task Pool preserves the task ID, completion state, highlight, and reminder. The moved title is trimmed.
- Reordering is performed with explicit controls, not drag and drop.
- Frequent row actions appear directly in this order: move to the other list, highlight, then move to top. Lower-frequency actions are placed in the more menu.
- The app window has a fixed width of 750 points.
- Blank titles are rejected during editing. The trash action is the deletion path.
- Language and font-size preferences are local app preferences.
- Reminders only fire while the app is running.

## Scope boundaries

Do not introduce cloud sync, accounts, recurring tasks, due dates, tags, priorities, project folders, menu-bar mode, or non-macOS clients unless a request explicitly changes the product scope.

## Persistence compatibility

Data is stored at `~/Library/Application Support/TopToDo/todos.json`. Current writes use `todayItems` and `taskPoolItems`; they must not write legacy date-reset metadata. Older `topItems` data remains readable, legacy boolean highlights map to red, and missing last-modified timestamps fall back to creation time. The app has no released-data migration requirement from the pre-release `iDo` name.

For local UI verification only, `TOPTODO_PERSISTENCE_URL` may point to an isolated JSON file. When it is absent or blank, the user-data location above remains unchanged.
