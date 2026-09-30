# Hymn content

Shared by every A2N Hymnal app.

- `hymns/<locale>/<Filename>.txt` — one hymn per file (`en-us`, `zh-cn`, `zh-tw`)
- `music/<Filename>.mp3` — its recording

`<Filename>` is the join key: a translation reuses the English filename, and the mp3 has the
same name. The file format (`key:: value` attributes separated by `---`, `text::` last,
`[Refrain]`/`[Tag]` markers) is described in `CLAUDE.md` at the repo root. The Apple app's
`HymnDataTests` check every file here.
