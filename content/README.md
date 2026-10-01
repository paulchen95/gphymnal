# Hymn content

Shared by every A2N Hymnal app.

- `hymns/<locale>/<Filename>.txt` — one hymn per file (`en-us`, `zh-cn`, `zh-tw`)
- `music/<Filename>.mp3` — its recording

- `FORMAT.md` — the hymn file format
- `fixtures/` — shared behaviour examples every app's tests run

`<Filename>` is the join key: a translation reuses the English filename, and the mp3 has the
same name. Run `tools/validate-content` after adding or editing hymns. It checks every file
here, for all apps.
