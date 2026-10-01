# Hymn file format

One hymn per file: `hymns/<locale>/<Filename>.txt`, UTF-8. Every app parses it the same way.
`fixtures/parsing.json` has worked examples, and `tools/validate-content` checks every file.

```
name:: Amazing Grace
---
author:: John Newton
---
composer:: Unknown
---
tune:: New Britain
---
text::
Amazing grace! How sweet the sound
That saved a wretch like me!

[Refrain]
...
```

- Attributes are `key:: value`, separated by lines containing `---`, with `text::` last.
- Keys: `name`, `author`, `translator`, `composer`, `arranger`, `tune`, `collection`, `text`.
  `name` and `text` are required. The rest are optional.
- **Two colons.** `tune: X` (one colon) is not an attribute and is silently ignored.
- Spaces around a value are trimmed. `text::` keeps the newline after the key, so lyrics
  start with a blank line.
- `collection:: Christmas` is the only value besides the default `Hymn` (used when absent).
- Inside `text::`, a line of exactly `[Refrain]` makes the following lines bold italic and
  `[Tag]` makes them italic, until the next blank line. The marker lines aren't shown.
- `<Filename>` (no spaces, PascalCase from the English title) is the join key. A translation
  reuses the English filename even though its `name::` is Chinese, and the recording is
  `music/<Filename>.mp3`.
