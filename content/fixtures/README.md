# Shared behaviour fixtures

Examples of rules every app must follow, as inputs and expected results. The Apple app runs
them in `apple/A2N HymnalTests/SharedFixtureTests.swift`, and the Android app will run the
same files. When a rule changes, change the fixture first. Each app's tests then show what
needs updating.

| File | Rule |
|---|---|
| `parsing.json` | Hymn file format (see `../FORMAT.md`) |
| `sections.json` | A–Z grouping and order, including pinyin initials for Chinese titles |
| `search.json` | Search matches title or lyrics, ignoring case |
| `links.json` | Hymn link slugs and URL forms |
| `text-size.json` | Lyrics text size steps and limits |
| `favorites.json` | The Favorites section at the top of the list |
